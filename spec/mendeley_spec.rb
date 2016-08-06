require File.expand_path '../spec_helper.rb', __FILE__

describe Mendeley do
  describe "#get" do
    it "should get folders", vcr: true do
      mendeley = Mendeley.new()
      #expect(last_response).to be_ok
      #expect(last_response.body).to match "Login"
    end
  end
end
