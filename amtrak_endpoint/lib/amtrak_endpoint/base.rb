module AmtrakEndpoint
  class Base < Sinatra::Application
    set :raise_errors, false
    set :show_exceptions, false
  end
end
