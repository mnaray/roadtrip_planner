class CreateStops < ActiveRecord::Migration[8.0]
  def change
    create_table :stops do |t|
      t.references :route, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.integer :order, null: false
      t.datetime :arrival_time
      t.datetime :departure_time
      t.text :notes
      
      t.timestamps
    end
    
    add_index :stops, [:route_id, :order], unique: true
    add_index :stops, :order
    add_index :stops, [:latitude, :longitude]
  end
end