class CreateWaypoints < ActiveRecord::Migration[8.0]
  def change
    create_table :waypoints do |t|
      t.references :route, null: false, foreign_key: true
      t.decimal :latitude, precision: 10, scale: 8, null: false
      t.decimal :longitude, precision: 11, scale: 8, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_index :waypoints, [ :route_id, :position ], unique: true
  end
end
