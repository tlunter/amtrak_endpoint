module AmtrakEndpoint
  class RegisterDevice < Base
    post %r{^/register/android/(?<device_id>[^/]+)/(?<train_number>[^\.]+)\.json} do
      headers['Content-Type'] = 'application/json'

      train_routes = JSON.parse(request.body.tap(&:rewind).read)

      train_routes.each do |train_route|
        uuid = UUIDTools::UUID.random_create
        device = AmtrakEndpoint::Device.new(uuid)
        device.type = 'android'
        device.type_params.clear
        device.type_params.update(
          train_number: params['train_number'],
          device_id: params['device_id']
        )

        AmtrakEndpoint::TrainRoute.new(
          from: train_route["from"], to: train_route["to"]
        ).devices << device.uuid
      end
      ""
    end
  end
end
