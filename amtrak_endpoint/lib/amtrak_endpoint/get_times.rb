module AmtrakEndpoint
  class GetTimes < Sinatra::Application
    KEY_EXPIRE_TIME = 60

    set :cache, AmtrakEndpoint::Cache.redis
    set :logger, Logger.new(STDOUT)

    def pretty_string(from, to, date)
      str =  "#{from}"
      str << ":#{to}"
      str << ":#{date.iso8601}" if date
      str
    end

    def get_train_data(from, to, date)
      train_fetcher = Amtrak::TrainFetcher.new(from, to, date: date)
      fail 'New Release!' unless train_fetcher.check_release
      train_fetcher.get.map do |html|
        Amtrak::TrainParser.parse(html)
      end.flatten
    end

    def amtrak_data(from, to, date)
      report = { from: from, to: to, date: date }
      if TraceView.tracing?
        settings.logger.debug('Tracing amtrak data')
        TraceView::API.trace('amtrak', report) do
          get_train_data(from, to, date)
        end
      else
        settings.logger.debug('Not tracing amtrak data')
        get_train_data(from, to, date)
      end
    end

    get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*).json} do
      headers['Content-Type'] = 'application/json'

      from = params["from"]
      to = params["to"]
      date = Date.parse(params["date"]) if params["date"]
      key = pretty_string(from, to, date)

      unless timings = settings.cache.get(key)
        settings.logger.debug("Getting new data for: #{key}")
        timings = amtrak_data(from, to, date).to_json
        settings.logger.debug("Caching new data for: #{key}")
        settings.cache.set(key, timings, ex: KEY_EXPIRE_TIME)
      end

      timings
    end
  end
end
