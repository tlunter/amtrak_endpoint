module AmtrakEndpoint
  class Base < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, false

    # Don't do anything if the route is missing
    def route_missing
      status 404
      ""
    end
  end
end
