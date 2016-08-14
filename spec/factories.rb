FactoryGirl.define do
  factory :annotation do
    sequence :uid do |i|
      "uid_#{i}"
    end
    sequence :folder do |i|
      "folder_#{i}"
    end
    sequence :name do |i|
      "annotation_#{i}"
    end
  end
  factory :item do
    sequence :name do |i|
      "item_#{i}"
    end
    association :annotation, factory: :annotation
  end
end
