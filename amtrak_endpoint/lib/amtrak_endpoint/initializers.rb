if ENV['RACK_ENV'] == 'production'
  TraceView::Config[:reporter_host] = ENV['DOCKER'] ? 'tracelyzer' : 'localhost'
  TraceView::Config[:tracing_mode] = 'always'
  TraceView::Config[:verbose] = true
  TraceView::Reporter.start
  TraceView::API.report_init('ruby')

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_TOKEN']
  end

  ::Sinatra::Base.use Rollbar::Middleware::Sinatra
end
