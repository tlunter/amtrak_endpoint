require 'sinatra'
require 'connection_pool'
require 'unicorn'
require 'redis'
require 'redis/objects'
require 'amtrak'
require 'json'
require 'logger'
require 'rollbar/middleware/sinatra'
require 'clockwork'
require 'resque'

require 'traceview'

require 'amtrak_endpoint/initializers'

# models
require 'amtrak_endpoint/train_route'

# tasks
require 'amtrak_endpoint/cache_train_times'
require 'amtrak_endpoint/enqueue_times'

# controllers
require 'amtrak_endpoint/base'
require 'amtrak_endpoint/get_times'
require 'amtrak_endpoint/register_device'

module AmtrakEndpoint
  class App < Sinatra::Application
    use AmtrakEndpoint::GetTimes
    use AmtrakEndpoint::RegisterDevice
  end

  module_function

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
