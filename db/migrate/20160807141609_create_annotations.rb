class CreateAnnotations < ActiveRecord::Migration[4.2]
  def change
    create_table :annotations do |t|
      t.string :uid
      t.string :folder
      t.string :name
    end
  end
end
