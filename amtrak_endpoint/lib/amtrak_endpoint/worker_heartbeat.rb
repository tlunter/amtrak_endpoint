module AmtrakEndpoint
  class WorkerHeartbeat
    @queue = :amtrak

    def self.perform
      client = Dogapi::Client.new(DATA_DOG_API_KEY)
      client.service_check('worker.heartbeat', 'docker', 0)
    end
  end
end
