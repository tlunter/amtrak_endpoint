require 'amtrak_endpoint'

STDOUT.sync = true

use Rack::CommonLogger, AmtrakEndpoint.logger
run AmtrakEndpoint::GetTimes.new
