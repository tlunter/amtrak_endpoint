module AmtrakEndpoint
  class CacheTrainTimes
    @queue = :amtrak

    def self.perform(identifier)
      train_route = TrainRoute.prepare(identifier)
      if train_route.used?
        AmtrakEndpoint.logger.info "Caching train times for: #{train_route.id}"
        train_route.cache_train_times
        train_route.alert_if_late_departure
      else
        AmtrakEndpoint.logger.info "Deleting: #{train_route.id}"
        train_route.delete
      end
    end
  end
end
