require 'sinatra'
require 'dalli'
require 'oboe'
require 'amtrak'
require 'json'
require 'logger'
require 'rollbar/middleware/sinatra'

Rollbar.configure do |config|
  config.access_token = ''
end

class AmtrakEndpoint < Sinatra::Application
  KEY_EXPIRE_TIME = 60

  if ENV['DOCKER']
    set :hosts, { :tracelyzer => 'tracelyzer', :memcached => 'memcached' }
  else
    set :hosts, { :tracelyzer => 'localhost', :memcached => '127.0.0.1' }
  end
  set :cache, Dalli::Client.new("#{settings.hosts[:memcached]}:11211")
  set :logger, Logger.new(STDOUT)

  if ENV['RACK_ENV'] == 'production'
    use Rollbar::Middleware::Sinatra
  end

  configure do
    if ENV['RACK_ENV'] == 'production'
      Oboe::Config[:reporter_host] = settings.hosts[:tracelyzer]
      Oboe::Config[:tracing_mode] = 'always'
      Oboe::Config[:verbose] = true
      Oboe::Reporter.start
      Oboe::API.report_init('ruby')
    end
  end

  def pretty_string(from, to, date)
    str =  "#{from}"
    str << ":#{to}"
    str << ":#{date.iso8601}" if date
    str
  end

  def get_train_data(from, to, date)
    train_fetcher = Amtrak::TrainFetcher.new(from, to, date: date)
    fail 'New Release!' unless train_fetcher.check_release
    train_fetcher.get.map do |html|
      Amtrak::TrainParser.parse(html)
    end.flatten
  end

  def amtrak_data(from, to, date)
    report = { from: from, to: to, date: date }
    if Oboe.tracing?
      settings.logger.debug('Tracing amtrak data')
      Oboe::API.trace('amtrak', report) do
        get_train_data(from, to, date)
      end
    else
      settings.logger.debug('Not tracing amtrak data')
      get_train_data(from, to, date)
    end
  end

  get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*).json} do
    headers['Content-Type'] = 'application/json'

    from = params["from"]
    to = params["to"]
    date = Date.parse(params["date"]) if params["date"]
    key = pretty_string(from, to, date)
    settings.cache.fetch(key, KEY_EXPIRE_TIME) do
      settings.logger.debug("Caching new data for: #{key}")
      amtrak_data(from, to, date).to_json
    end
  end

  get %r{^/} do
    erb :index
  end
end

run AmtrakEndpoint
