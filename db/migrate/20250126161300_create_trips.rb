class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.string :name, null: false
      t.text :description
      t.date :start_date, null: false
      t.date :end_date, null: false
      
      t.timestamps
    end
    
    add_index :trips, :start_date
    add_index :trips, :end_date
  end
end