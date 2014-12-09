require 'sinatra'
require 'dalli'
require 'oboe'
require 'amtrak'
require 'json'

if ENV['RACK_ENV'] == 'production'
  Oboe::Config[:tracing_mode] = 'through'
end

class AmtrakEndpoint < Sinatra::Base
  KEY_EXPIRE_TIME = 60

  set :cache, Dalli::Client.new

  def pretty_string(from, to, date)
    str =  "#{from}"
    str << ":#{to}"
    str << ":#{date.iso8601}" if date
  end

  get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*).json} do
    headers['Content-Type'] = 'application/json'

    from = params["from"]
    to = params["to"]
    date = Date.parse(params["date"]) if params["date"]
    key = pretty_string(from, to, date)
    settings.cache.fetch(key, KEY_EXPIRE_TIME) do
      Amtrak.get(from, to, date: date).to_json
    end
  end

  get %r{^/} do
  end
end

run AmtrakEndpoint
