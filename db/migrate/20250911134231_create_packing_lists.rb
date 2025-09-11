class CreatePackingLists < ActiveRecord::Migration[8.0]
  def change
    create_table :packing_lists do |t|
      t.string :name
      t.references :road_trip, null: false, foreign_key: true

      t.timestamps
    end
  end
end
