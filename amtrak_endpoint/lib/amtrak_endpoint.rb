require 'sinatra'
require 'active_support'
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
require 'uuidtools'
require 'dogapi'

require 'traceview'

require 'amtrak_endpoint/initializers'

# models
require 'amtrak_endpoint/train_route'

# tasks
require 'amtrak_endpoint/cache_train_times'
require 'amtrak_endpoint/enqueue_times'
require 'amtrak_endpoint/worker_heartbeat'

# controllers
require 'amtrak_endpoint/base'
require 'amtrak_endpoint/get_times'

module AmtrakEndpoint
  module_function

  class CustomLogger < Logger
    def write(*args)
      debug(*args)
    end
  end

  def logger
    @logger ||= CustomLogger.new(STDOUT)
  end
end
