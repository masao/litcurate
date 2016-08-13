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
end
