require "erb"
require "sinatra"
require "sinatra/activerecord"
require "sinatra/json"
require "omniauth"
require "omniauth-mendeley_oauth2"
require "rack"
require "rack/contrib"
require "i18n"
require "i18n/backend/fallbacks"

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

  configure do
    I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    I18n.backend.load_translations
    I18n.default_locale = :en
    I18n.enforce_available_locales = false
  end
  use Rack::Locale

  get "/" do
    if login?
      begin 
        @mendeley = Mendeley.new(session[:access_token])
        @folders = @mendeley.get("/folders")
      rescue Mendeley::Error
        redirect to "/logout"
      end
    end
    erb :index
  end
  get "/about" do
    erb :about
  end

  get "/load_folders" do
    content_type "text/json"
    authorize!
    @mendeley = Mendeley.new(session[:access_token])
    response = @mendeley.get("/folders")
    json response
  end
  get "/load_documents" do
    content_type "text/json"
    authorize!
    check_param!("folder")
    @mendeley = Mendeley.new(session[:access_token])
    path = File.join("folders", params["folder"], "documents")
    response = @mendeley.get(path)
    json response
  end
  get "/load_document" do
    content_type "text/json"
    authorize!
    check_param!("id")
    @mendeley = Mendeley.new(session[:access_token])
    path = File.join("documents", params["id"])
    path << "?view=all"
    response = @mendeley.get(path)
    json response
  end
  post "/update_document" do
    content_type "text/json"
    authorize!
    check_param!("id", "annotation", "item")
    @mendeley = Mendeley.new(session[:access_token])
    path = File.join("documents", params["id"])
    body = { tags: [ "#{params["annotation"]}-#{params["item"]}" ] }.to_json
    response = @mendeley.patch(path, body)
    json response
  end
  get "/load_annotations" do
    content_type "text/json"
    authorize!
    check_param!("folder")
    annotations = Annotation.where(uid: session[:uid], folder: params["folder"])
    result = []
    annotations.each do |annotation|
      result << {
        id: annotation.id,
        uid: annotation.uid,
        folder: annotation.folder,
        name: annotation.name,
      }
    end
    json result
  end
  get "/load_items" do
    content_type "text/json"
    authorize!
    check_param!("annotation")
    annotation = Annotation.find params[:annotation]
    if annotation.blank? or annotation.uid != session[:uid]
      halt 400, json(error: "annotation '#{params[:annotation]}' is not found.")
    end
    json annotation.items
  end

  post "/new_annotation" do
    content_type "text/json"
    authorize!
    check_param!("folder", "name", "item")
    annotation = Annotation.create(uid: session[:uid], folder: params[:folder], name: params["name"])
    params[:item].each do |e|
      item = Item.create(annotation: annotation, name: e)
      item.save!
      annotation.items << item
      annotation.save!
    end
    json annotation
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
    def authorize!
      if not login?
        halt 403, json(error: "You are not logged in. Please login first.")
      end
    end
    def check_param!(*parameters)
      parameters.each do |param|
        if not params.has_key? param
          halt 400, json(error: "#{param} is not specified. Please specify the parameter '#{param}' to proceed.")
        end
      end
    end
    def login?
      session.has_key? :uid
    end
    def current_page?(path)
      request.path_info == path
    end
    def t(*arg)
      I18n.t(*arg)
    end
  end
end
