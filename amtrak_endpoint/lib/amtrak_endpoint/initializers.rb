if ENV['RACK_ENV'] == 'production'
  TraceView::Config[:reporter_host] = ENV['DOCKER'] ? 'tracelyzer' : 'localhost'
  TraceView::Config[:tracing_mode] = 'always'
  TraceView::Config[:verbose] = true
  TraceView::Reporter.start
  TraceView::API.report_init('ruby')

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_TOKEN']
  end

  require 'resque/failure/multiple'
  require 'resque/failure/redis'
  require 'resque/rollbar'

  Resque::Failure::Multiple.classes = [ Resque::Failure::Redis, Resque::Failure::Rollbar ]
  Resque::Failure.backend = Resque::Failure::Multiple

  ::Sinatra::Base.use Rollbar::Middleware::Sinatra

  DATA_DOG_API_KEY = ENV['DATA_DOG_API_KEY']
  GCM_API_KEY = ENV['GCM_API_KEY']
end

REDIS_HOST = ENV['DOCKER'] ? 'redis' : 'localhost'
Redis::Objects.redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new(:host => REDIS_HOST, :port => 6379) }
