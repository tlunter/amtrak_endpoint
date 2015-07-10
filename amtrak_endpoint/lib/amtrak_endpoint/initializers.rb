if ENV['RACK_ENV'] == 'production'
  Oboe::Config[:reporter_host] = ENV['DOCKER'] ? 'tracelyzer' : 'localhost'
  Oboe::Config[:tracing_mode] = 'always'
  Oboe::Config[:verbose] = true
  Oboe::Reporter.start
  Oboe::API.report_init('ruby')

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_TOKEN']
  end

  ::Sinatra::Base.use Rollbar::Middleware::Sinatra
end
