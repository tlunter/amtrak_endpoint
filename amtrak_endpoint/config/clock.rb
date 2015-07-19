require 'clockwork'
require 'resque'

module Clockwork
  handler { |job| Resque.enqueue(job) }

  every(1.minute, AmtrakEndpoint::EnqueueTimes)
end
