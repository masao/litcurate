class Annotation < ActiveRecord::Base
  has_many :items, dependent: :destroy
  validates_presence_of :uid
  validates_presence_of :folder
  validates_presence_of :name
end

class Item < ActiveRecord::Base
  belongs_to :annotation
  validates_presence_of :name
  validates_associated :annotation
end
