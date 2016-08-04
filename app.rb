require "erb"
require "sinatra"
require "sinatra/config_file"

require_relative "mendeley.rb"

class App < Sinatra::Base
  use Rack::Session::Cookie
  use OmniAuth::Strategies::Developer
  enable :sessions

  register Sinatra::ConfigFile
  config_file "mendelurvey.yml"
  get "/" do
    erb :index
  end
  helpers ERB::Util
end
