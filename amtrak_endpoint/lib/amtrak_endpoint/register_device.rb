module AmtrakEndpoint
  class RegisterDevice < Base
    post %r{^/register/android\.json} do
      headers['Content-Type'] = 'application/json'

      body = request.body.tap(&:rewind).read

      AmtrakEndpoint.logger.debug(
        "Registering device: #{params['device_id']} with: #{body}"
      )
      train_routes = JSON.parse(body)
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
