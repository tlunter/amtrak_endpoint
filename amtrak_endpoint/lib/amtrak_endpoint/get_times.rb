module AmtrakEndpoint
  class GetTimes < Base
    get %r{^(\/api)?\/(?<from>[^\/.]*)\/(?<to>[^\/.]*)\.json} do
      headers['Content-Type'] = 'application/json'

      from = params["from"]
      to = params["to"]
      date = Date.parse(params["date"]).iso8601 if params["date"]

      if from.nil? || to.nil?
        status 400
        return ""
      end

      train_route = TrainRoute.new(from: from, to: to, date: date)
      train_route.last_request = DateTime.now

      tr = train_route
        .get_latest_times(TrainRoute::MAX_TIMES)
        .reject(&:empty?)
        .first
      tr ||= train_route.cache_train_times

      tr.to_json
    end
  end
end
