require File.expand_path '../spec_helper.rb', __FILE__

describe Item do
  it "should have a valid item" do
    create(:item)
    expect(Item.all).to be_exist
    item = Item.all.last
    expect(item).to be_valid
    expect(item).not_to be_blank
    expect(item.name).not_to be_blank
    expect(item.annotation).not_to be_blank
  end
end
