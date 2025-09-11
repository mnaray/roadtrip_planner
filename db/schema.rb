# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_11_134246) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "packing_list_items", force: :cascade do |t|
    t.string "name", null: false
    t.integer "quantity", default: 1, null: false
    t.string "category", null: false
    t.boolean "packed", default: false, null: false
    t.bigint "packing_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["packing_list_id"], name: "index_packing_list_items_on_packing_list_id"
  end

  create_table "packing_lists", force: :cascade do |t|
    t.string "name"
    t.bigint "road_trip_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["road_trip_id"], name: "index_packing_lists_on_road_trip_id"
  end

  create_table "road_trips", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_road_trips_on_user_id"
  end

  create_table "routes", force: :cascade do |t|
    t.string "starting_location"
    t.string "destination"
    t.datetime "datetime"
    t.bigint "road_trip_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "distance"
    t.float "duration"
    t.index ["road_trip_id"], name: "index_routes_on_road_trip_id"
    t.index ["user_id"], name: "index_routes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "packing_list_items", "packing_lists"
  add_foreign_key "packing_lists", "road_trips"
  add_foreign_key "road_trips", "users"
  add_foreign_key "routes", "road_trips"
  add_foreign_key "routes", "users"
end
