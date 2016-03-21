class AddResultToItems < ActiveRecord::Migration
  def change
  	add_column :items, :result, :string
  end
end
