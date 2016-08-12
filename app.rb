require "erb"
require "sinatra"
require "sinatra/activerecord"
require "sinatra/json"
require "omniauth"
require "omniauth-mendeley_oauth2"

require_relative "mendeley.rb"
require_relative "models.rb"

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
  register Sinatra::ActiveRecordExtension
  #set :database, {adapter: "sqlite3", database: "development.sqlite3"}

  get "/" do
    if login?
      begin 
        @mendeley = Mendeley.new(session[:access_token])
        @folders = @mendeley.get("/folders")
      rescue Mendeley::Error => e
        redirect to "/logout"
      end
    end
    erb :index
  end

  get "/load_documents" do
    content_type "text/json"
    @mendeley = Mendeley.new(session[:access_token])
    path = File.join("folders", params["folder"], "documents")
    response = @mendeley.get(path)
    json response
  end

  get "/auth/:provider/callback" do
    result = request.env['omniauth.auth']
    session[:uid] = result["uid"]
    session[:access_token] = result["credentials"]["token"]
    session[:name] = result["info"]["name"]
    session[:email] = result["info"]["email"]
    session[:image] = result["info"]["image"]
    session[:url] = result["info"]["urls"][ result["provider"] ]
    redirect to "/"
    erb "<a href='/'>Top</a><br>
      <h1>#{params[:provider]}</h1>
      <pre>#{JSON.pretty_generate(result)}</pre>"
  end
  get "/logout" do
    session.clear
    redirect to "/"
  end

  helpers ERB::Util
  helpers do
    def login?
      session.has_key? :uid
    end
  end
end
