require File.expand_path '../spec_helper.rb', __FILE__

describe App do
  it "should have login link" do
    get "/"
    expect(last_response).to be_ok
    expect(last_response.body).to match "Login"
  end

  it "should have about page" do
    get "/about"
    expect(last_response).to be_ok
  end

  context "I18n feature" do
    it "should respect Accept header" do
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to match /Login/
      env "HTTP_ACCEPT_LANGUAGE", "ja"
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to match /ログイン/
      env "HTTP_ACCEPT_LANGUAGE", "ja-JP"
      get "/"
      expect(last_response).to be_ok
      expect(last_response.body).to match /ログイン/
    end
    it "should switch page content" do
      get "/about"
      expect(last_response.body).to match /<strong>LitCurate<\/strong> is a tool/
      env "HTTP_ACCEPT_LANGUAGE", "ja"
      get "/about"
      expect(last_response.body).to match /<strong>LitCurate<\/strong>は/
    end
  end

  context "/load_annotations" do
    it "should load annotations" do
      annotation = FactoryGirl.create(:annotation)
      env "rack.session", { uid: annotation.uid }
      get "/load_annotations", {folder: annotation.folder}
      expect(last_response).to be_ok
      json = JSON.load(last_response.body)
      expect(json).to respond_to(:each)
      obj = json.last
      expect(obj["uid"]).to eq annotation.uid
      expect(obj["name"]).to eq annotation.name
      expect(obj["folder"]).to eq annotation.folder
    end
    it "should raise errors with missing parameters" do
      get "/load_annotations"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 403
      obj = JSON.load(last_response.body)
      expect(obj).to have_key("error")
      env "rack.session", { uid: "dummy" }
      get "/load_annotations"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 400
      obj = JSON.load(last_response.body)
      expect(obj).to have_key("error")
    end
  end

  context "/load_items" do
    it "should load items" do
      item = FactoryGirl.create(:item)
      env "rack.session", { uid: item.annotation.uid }
      get "/load_items", annotation: item.annotation.id
      expect(last_response).to be_ok
      obj = JSON.load(last_response.body)
      expect(obj).not_to be_blank
      expect(obj.first["name"]).to eq item.name
    end
    it "should raise errors with missing parameters" do
      get "/load_items"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 403
      obj = JSON.load(last_response.body)
      expect(obj).to have_key("error")
      env "rack.session", { uid: "dummy" }
      get "/load_items"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 400
      obj = JSON.load(last_response.body)
      expect(obj).to have_key("error")
    end
  end

  context "/new_annotation" do
    it "should accept POST parameters" do
      get "/new_annotation"
      expect(last_response).not_to be_ok
      post "/new_annotation"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 403

      number_of_annotations = Annotation.all.size
      env "rack.session", { uid: "dummy-uid" }
      dummy_params = {folder: "dummy", name: "name", "item": ["item-1", "item-2"]}
      post "/new_annotation", dummy_params
      expect(last_response).to be_ok
      expect(Annotation.all.size).to eq number_of_annotations+1
    end
  end

  context "/delete_annotation" do
    it "should accept POST parameters" do
      get "/delete_annotation"
      expect(last_response).not_to be_ok
      post "/delete_annotation"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 403

      annotation = FactoryGirl.create(:annotation)
      env "rack.session", { uid: annotation.uid }
      dummy_params = {annotation: annotation.id, folder: annotation.folder}
      post "/delete_annotation", dummy_params
      expect(last_response).to be_ok
    end
  end

  context "/save_annotation" do
    it "should accept POST parameters" do
      annotation = FactoryGirl.create(:annotation)
      env "rack.session", { uid: annotation.uid }
      get "/save_annotation"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 404
      post "/save_annotation"
      expect(last_response).not_to be_ok
      expect(last_response.status).to eq 400
      post "/save_annotation", { id: annotation.id }
      expect(last_response).not_to be_ok
      post "/save_annotation", { id: annotation.id }
      expect(last_response).not_to be_ok
      post "/save_annotation", { id: annotation.id, name: "name" }
      expect(last_response).not_to be_ok
      post "/save_annotation", { id: annotation.id, name: "name", folder: annotation.folder }
      expect(last_response).not_to be_ok
      post "/save_annotation", { id: annotation.id, name: "name", folder: annotation.folder, item: ["item-1", "item-2"] }
      expect(last_response).to be_ok
      annotation.reload
      expect(annotation.items.size).to eq 2
      expect(annotation.items[0].name).to eq "item-1"
      expect(annotation.items[1].name).to eq "item-2"
    end
  end
end
