module AmtrakEndpoint
  module Cache
    module_function

    def redis
      Redis.new(host: host, port: 6379)
    end

    def host
      ENV['DOCKER'] ? 'redis' : 'localhost'
    end
  end
end
