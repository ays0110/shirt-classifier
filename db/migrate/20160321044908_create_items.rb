class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :category
      t.string :item_type
      t.string :phash

      t.timestamps null: false
    end
  end
end
