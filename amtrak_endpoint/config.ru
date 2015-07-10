$LOAD_PATH.unshift(File.join(Dir.pwd, 'lib'))
require 'amtrak_endpoint'

run AmtrakEndpoint::App
