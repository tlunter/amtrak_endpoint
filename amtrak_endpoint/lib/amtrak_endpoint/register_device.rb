module AmtrakEndpoint
  class RegisterDevice < Base
    post %r{^/register/(?<device_id>[^.]*)\.json} do
      headers['Content-Type'] = 'application/json'

      device_id = params["device_id"]
      train_routes = JSON.parse(request.body.tap(&:rewind).read)

      train_routes.each do |train_route|
        AmtrakEndpoint::TrainRoute.new(
          from: train_route["from"], to: train_route["to"]
        ).devices << device_id
      end
      ""
    end
  end
end
