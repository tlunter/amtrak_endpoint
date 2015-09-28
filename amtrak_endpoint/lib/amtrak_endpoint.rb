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
require 'uuidtools'
require 'dogapi'
require 'gcm'

require 'traceview'

require 'amtrak_endpoint/initializers'

# models
require 'amtrak_endpoint/train_route'
require 'amtrak_endpoint/device'

# tasks
require 'amtrak_endpoint/cache_train_times'
require 'amtrak_endpoint/enqueue_times'
require 'amtrak_endpoint/worker_heartbeat'

# controllers
require 'amtrak_endpoint/base'
require 'amtrak_endpoint/get_times'
require 'amtrak_endpoint/register_device'

module AmtrakEndpoint
  module_function

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def gcm
    @gcm ||= GCM.new(GCM_API_KEY)
  end

  class App < Base
    use Rack::CommonLogger, AmtrakEndpoint.logger
    use AmtrakEndpoint::GetTimes
    use AmtrakEndpoint::RegisterDevice
  end
end
