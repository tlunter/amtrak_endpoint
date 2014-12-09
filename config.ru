require 'sinatra'
require 'dalli'
require 'oboe'
require 'amtrak'
require 'json'

if ENV['RACK_ENV'] == 'production'
  Oboe::Config[:tracing_mode] = 'through'
end

class AmtrakEndpoint < Sinatra::Base
  set :cache, Dalli::Client.new

  def pretty_string(from, to, date, minute)
    str =  "#{from}"
    str << ":#{to}"
    str << ":#{date.iso8601}" if date
    str << ":#{minute}"
  end

  get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*).json} do
    headers['Content-Type'] = 'application/json'

    from = params["from"]
    to = params["to"]
    date = Date.parse(params["date"]) if params["date"]
    minute = (Time.now.to_i / 60)
    settings.cache.fetch(pretty_string(from, to, date, minute)) do
      Amtrak.get(from, to, date: date).to_json
    end
  end

  get %r{^/} do
  end
end

run AmtrakEndpoint
