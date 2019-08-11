# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_12_044212) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accommodation_location_details", id: :serial, force: :cascade do |t|
    t.integer "location_id"
    t.integer "accommodation_id"
    t.string "cost", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["accommodation_id"], name: "index_accommodation_location_details_on_accommodation_id"
    t.index ["location_id"], name: "index_accommodation_location_details_on_location_id"
  end

  create_table "accommodations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "icon_file_name", limit: 255
    t.string "icon_content_type", limit: 255
    t.integer "icon_file_size"
    t.datetime "icon_updated_at"
    t.string "cost_ranges", limit: 255, array: true
  end

  create_table "accommodations_locations", id: false, force: :cascade do |t|
    t.integer "location_id"
    t.integer "accommodation_id"
    t.index ["accommodation_id"], name: "index_accommodations_locations_on_accommodation_id"
    t.index ["location_id"], name: "index_accommodations_locations_on_location_id"
  end

  create_table "climbing_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "icon_file_name", limit: 255
    t.string "icon_content_type", limit: 255
    t.integer "icon_file_size"
    t.datetime "icon_updated_at"
  end

  create_table "climbing_types_locations", id: false, force: :cascade do |t|
    t.integer "location_id"
    t.integer "climbing_type_id"
    t.index ["climbing_type_id"], name: "index_climbing_types_locations_on_climbing_type_id"
    t.index ["location_id"], name: "index_climbing_types_locations_on_location_id"
  end

  create_table "food_option_location_details", id: :serial, force: :cascade do |t|
    t.integer "location_id"
    t.integer "food_option_id"
    t.string "cost", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["food_option_id"], name: "index_food_option_location_details_on_food_option_id"
    t.index ["location_id"], name: "index_food_option_location_details_on_location_id"
  end

  create_table "food_options", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cost_ranges", limit: 255, array: true
  end

  create_table "grades", id: :serial, force: :cascade do |t|
    t.string "us", limit: 255
    t.string "french", limit: 255
    t.string "australian", limit: 255
    t.string "south_african", limit: 255
    t.string "uiaa", limit: 255
    t.string "uk", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "order"
    t.integer "climbing_type_id"
    t.index ["climbing_type_id"], name: "index_grades_on_climbing_type_id"
  end

  create_table "grades_locations", id: false, force: :cascade do |t|
    t.integer "location_id"
    t.integer "grade_id"
    t.index ["grade_id"], name: "index_grades_locations_on_grade_id"
    t.index ["location_id"], name: "index_grades_locations_on_location_id"
  end

  create_table "info_sections", id: :serial, force: :cascade do |t|
    t.string "title", limit: 255
    t.text "body"
    t.json "metadata"
    t.integer "location_id"
    t.index ["location_id"], name: "index_info_sections_on_location_id"
  end

  create_table "location_edits", id: :serial, force: :cascade do |t|
    t.integer "location_id"
    t.string "edit_type", limit: 255
    t.json "edit"
    t.boolean "approved", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["location_id"], name: "index_location_edits_on_location_id"
  end

  create_table "locations", id: :serial, force: :cascade do |t|
    t.string "continent", limit: 255
    t.string "name", limit: 255
    t.integer "grade_id"
    t.float "latitude", default: 1.0
    t.float "longitude", default: 1.0
    t.integer "price_range_floor_cents", default: 0, null: false
    t.string "price_range_floor_currency", limit: 255, default: "USD", null: false
    t.integer "price_range_ceiling_cents", default: 0, null: false
    t.string "price_range_ceiling_currency", limit: 255, default: "USD", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "home_thumb_file_name", limit: 255
    t.string "home_thumb_content_type", limit: 255
    t.integer "home_thumb_file_size"
    t.datetime "home_thumb_updated_at"
    t.string "country", limit: 255
    t.string "slug", limit: 255
    t.string "airport_code", limit: 255
    t.boolean "active", default: false
    t.string "submitter_email", limit: 255
    t.string "closest_accommodation", limit: 255
    t.boolean "walking_distance"
    t.text "getting_in_notes"
    t.text "accommodation_notes"
    t.text "common_expenses_notes"
    t.text "saving_money_tips"
    t.integer "rating", default: 3
    t.boolean "solo_friendly"
    t.index ["grade_id"], name: "index_locations_on_grade_id"
  end

  create_table "locations_seasons", id: false, force: :cascade do |t|
    t.integer "location_id"
    t.integer "season_id"
    t.index ["location_id"], name: "index_locations_seasons_on_location_id"
    t.index ["season_id"], name: "index_locations_seasons_on_season_id"
  end

  create_table "locations_transportations", id: false, force: :cascade do |t|
    t.integer "location_id"
    t.integer "transportation_id"
    t.index ["location_id"], name: "index_locations_transportations_on_location_id"
    t.index ["transportation_id"], name: "index_locations_transportations_on_transportation_id"
  end

  create_table "primary_transportations", id: :serial, force: :cascade do |t|
    t.integer "transportation_id"
    t.integer "location_id"
    t.string "cost", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["location_id"], name: "index_primary_transportations_on_location_id"
    t.index ["transportation_id"], name: "index_primary_transportations_on_transportation_id"
  end

  create_table "seasons", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "icon_file_name", limit: 255
    t.string "icon_content_type", limit: 255
    t.integer "icon_file_size"
    t.datetime "icon_updated_at"
    t.integer "numerical_value"
  end

  create_table "transportations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cost_ranges", limit: 255, array: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "oauth_token"
    t.datetime "oauth_expires_at"
    t.string "username"
    t.string "password"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "version_associations", id: :serial, force: :cascade do |t|
    t.integer "version_id"
    t.string "foreign_key_name", limit: 255, null: false
    t.integer "foreign_key_id"
    t.index ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key"
    t.index ["version_id"], name: "index_version_associations_on_version_id"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", limit: 255, null: false
    t.integer "item_id", null: false
    t.string "event", limit: 255, null: false
    t.string "whodunnit", limit: 255
    t.text "object"
    t.datetime "created_at"
    t.text "object_changes"
    t.integer "transaction_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["transaction_id"], name: "index_versions_on_transaction_id"
  end

end
