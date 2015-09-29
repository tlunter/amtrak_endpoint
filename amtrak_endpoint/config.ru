require 'amtrak_endpoint'

STDOUT.sync = true

use Rack::CommonLogger, AmtrakEndpoint.logger
run Rack::Cascade.new([AmtrakEndpoint::RegisterDevice, AmtrakEndpoint::GetTimes])
