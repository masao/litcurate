require File.expand_path '../spec_helper.rb', __FILE__

describe App do
  it "should have login link" do
    get "/"
    expect(last_response).to be_ok
  end
end
