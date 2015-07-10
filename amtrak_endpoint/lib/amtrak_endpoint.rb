require 'sinatra'
require 'redis'
require 'traceview'
require 'amtrak'
require 'json'
require 'logger'
require 'rollbar/middleware/sinatra'

require 'amtrak_endpoint/initializers'

require 'amtrak_endpoint/cache'
require 'amtrak_endpoint/get_times'

module AmtrakEndpoint
  class App < Sinatra::Application
    use AmtrakEndpoint::GetTimes
  end
end
