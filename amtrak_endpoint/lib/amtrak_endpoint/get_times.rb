module AmtrakEndpoint
  class GetTimes < Base
    KEY_EXPIRE_TIME = 60

    def pretty_string(from, to, date)
      str =  "#{from}"
      str << ":#{to}"
      str << ":#{date.iso8601}" if date
      str
    end

    def amtrak_data(from, to, date)
      report = { from: from, to: to, date: date }
      if TraceView.tracing?
        AmtrakEndpoint.logger.debug('Tracing amtrak data')
        TraceView::API.trace('amtrak', report) do
          Amtrak.get(from, to, date: date)
        end
      else
        AmtrakEndpoint.logger.debug('Not tracing amtrak data')
        Amtrak.get(from, to, date: date)
      end
    end

    get %r{^/(?<from>[^/.]*)/(?<to>[^/.]*)\.json} do
      headers['Content-Type'] = 'application/json'

      from = params["from"]
      to = params["to"]
      date = Date.parse(params["date"]) if params["date"]
      key = pretty_string(from, to, date)

      AmtrakEndpoint::Cache.find_or_create(key, expiration: KEY_EXPIRE_TIME) do
        amtrak_data(from, to, date).to_json
      end
    end
  end
end
