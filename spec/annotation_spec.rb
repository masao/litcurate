require File.expand_path '../spec_helper.rb', __FILE__

describe Annotation do
  it "should have a valid record" do
    annotation = create(:annotation)
    expect(Annotation.all).to be_exist
    expect(annotation).to be_valid
    expect(annotation).not_to be_blank
    expect(annotation.uid).not_to be_blank
    expect(annotation.items).to be_empty
    expect(annotation.folder).not_to be_blank
    expect(annotation.name).not_to be_blank
    create(:item, annotation: annotation)
    expect(annotation.items).not_to be_empty
  end
end
