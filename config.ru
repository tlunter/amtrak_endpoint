require 'pry'
require 'sinatra'
require 'oboe'
require 'amtrak'
require 'json'

if ENV['RACK_ENV'] == 'production'
  Oboe::Config[:tracing_mode] = 'through'
end

class AmtrakEndpoint < Sinatra::Base
  get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*).json} do
    headers['Content-Type'] = 'application/json'

    from = params["from"]
    to = params["to"]
    date = Date.parse(params["date"]) if params["date"]
    Amtrak.get(from, to, date: date).to_json
  end

  get %r{^/} do
  end
end

run AmtrakEndpoint
