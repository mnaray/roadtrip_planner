class CreateRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :routes do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :day_number, null: false
      t.decimal :total_distance, precision: 10, scale: 2
      t.integer :estimated_duration_minutes
      t.text :notes
      
      t.timestamps
    end
    
    add_index :routes, [:trip_id, :day_number], unique: true
    add_index :routes, :day_number
  end
end