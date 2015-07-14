module AmtrakEndpoint
  class RegisterDevice < Base
    post %r{^/register/(?<device_id>[^.]*)\.json} do
      headers['Content-Type'] = 'application/json'

      device_id = params["device_id"]
      train_routes = JSON.parse(request.body.tap(&:rewind).read)

      train_routes.each do |train_route|
        key = [train_route["from"], train_route["to"]].join(':')
        AmtrakEndpoint::Cache.redis.sadd(
          "train_route:#{key}", device_id
        )
      end
      ""
    end
  end
end
