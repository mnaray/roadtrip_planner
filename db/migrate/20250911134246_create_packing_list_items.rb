class CreatePackingListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :packing_list_items do |t|
      t.string :name, null: false
      t.integer :quantity, default: 1, null: false
      t.string :category, null: false
      t.boolean :packed, default: false, null: false
      t.references :packing_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
