class CreateRoadTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :road_trips do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
