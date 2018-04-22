module AmtrakEndpoint
  class Base < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, false
    set :static, true
    set :public_folder, File.expand_path("../../../public", __FILE__)

    get '/' do
      send_file File.join(settings.public_folder, 'index.html')
    end

    # Don't do anything if the route is missing
    def route_missing
      status 404
      ""
    end
  end
end
