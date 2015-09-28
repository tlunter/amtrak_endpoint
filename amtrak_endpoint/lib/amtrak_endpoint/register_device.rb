module AmtrakEndpoint
  class RegisterDevice < Base
    post %r{^/register/android\.json} do
      headers['Content-Type'] = 'application/json'

      train_routes = JSON.parse(request.body.tap(&:rewind).read)

      train_routes.each do |train_route|
        device = AmtrakEndpoint::Device.new(params['device_id'])
        device.type = 'android'

        AmtrakEndpoint::TrainRoute.new(
          from: train_route["from"], to: train_route["to"]
        ).devices << device.uuid
      end
      ""
    end
  end
end
