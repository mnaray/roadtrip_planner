class CreateRoadTripParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :road_trip_participants do |t|
      t.references :road_trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :road_trip_participants, [:road_trip_id, :user_id], unique: true
  end
end
