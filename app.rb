require "erb"
require "sinatra"
require "omniauth"
require "omniauth-mendeley_oauth2"

require_relative "mendeley.rb"

# Workaround for omniauth-oauth2 changes...
# cf. https://github.com/intridea/omniauth-oauth2/pull/82
class OmniAuth::Strategies::Mendeley
  def callback_url
    options[:redirect_uri] || (full_host + script_name + callback_path)
  end
end

class App < Sinatra::Base
  set :sessions, secret: "LitCurate"
  use OmniAuth::Builder do
    provider :mendeley, ENV['MENDELEY_CLIENT_ID'], ENV['MENDELEY_CLIENT_SECRET']
  end

  get "/" do
    erb :index
  end

  get "/auth/:provider/callback" do
    result = request.env['omniauth.auth']
    erb "<a href='/'>Top</a><br>
      <h1>#{params[:provider]}</h1>
      <pre>#{JSON.pretty_generate(result)}</pre>"
  end

  helpers ERB::Util
end
