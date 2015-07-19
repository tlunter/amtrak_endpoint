module AmtrakEndpoint
  class GetTimes < Base
    get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*)\.json} do
      headers['Content-Type'] = 'application/json'

      from = params["from"]
      to = params["to"]
      date = Date.parse(params["date"]).iso8601 if params["date"]

      train_route = TrainRoute.new(from: from, to: to, date: date)
      train_route.last_request = DateTime.now
      if tr = train_route.get_latest_times.first
        tr.to_json
      else
        train_route.cache_train_times
      end
    end
  end
end
