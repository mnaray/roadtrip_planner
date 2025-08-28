class CreateRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :routes do |t|
      t.string :starting_location
      t.string :destination
      t.datetime :datetime
      t.references :road_trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
