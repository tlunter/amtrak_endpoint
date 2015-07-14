module AmtrakEndpoint
  module Cache
    module_function

    def find_or_create(key, expiration: nil)
      fail 'No block passed to get un-cached data' unless block_given?
      unless value = redis.get(key)
        AmtrakEndpoint.logger.debug("Getting new data for: #{key}")
        value = yield
        AmtrakEndpoint.logger.debug("Caching new data for: #{key}")
        redis.set(key, value, ex: expiration)
      end

      value
    end

    def redis
      Redis.new(host: host, port: 6379)
    end

    def host
      ENV['DOCKER'] ? 'redis' : 'localhost'
    end
  end
end
