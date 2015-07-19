module AmtrakEndpoint
  class EnqueueTimes
    @queue = :amtrak

    def self.perform
      train_routes = TrainRoute.redis
        .keys("#{TrainRoute.redis_prefix}:*")
        .map { |id| id.split(':')[1] }
        .uniq

      AmtrakEndpoint.logger.info "Enqueueing train routes: #{train_routes}"
      train_routes.each do |train_route|
        Resque.enqueue(CacheTrainTimes, train_route)
      end
    end
  end
end
