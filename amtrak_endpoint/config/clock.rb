module Clockwork
  handler { |job| Resque.enqueue(job) }

  every(1.minute, AmtrakEndpoint::EnqueueTimes)

  if ENV['RACK_ENV'] == 'production'
    every(1.minute, 'clock.heartbeat') do
      client = Dogapi::Client.new(DATA_DOG_API_KEY)
      client.service_check('clock.heartbeat', 'docker', 0)
    end

    every(1.minute, AmtrakEndpoint::WorkerHeartbeat)
  end
end
