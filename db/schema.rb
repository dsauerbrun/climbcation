# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160305154454) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accommodation_location_details", force: true do |t|
    t.integer  "location_id"
    t.integer  "accommodation_id"
    t.string   "cost"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accommodation_location_details", ["accommodation_id"], name: "index_accommodation_location_details_on_accommodation_id", using: :btree
  add_index "accommodation_location_details", ["location_id"], name: "index_accommodation_location_details_on_location_id", using: :btree

  create_table "accommodations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.string   "cost_ranges",       array: true
  end

  create_table "accommodations_locations", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "accommodation_id"
  end

  add_index "accommodations_locations", ["accommodation_id"], name: "index_accommodations_locations_on_accommodation_id", using: :btree
  add_index "accommodations_locations", ["location_id"], name: "index_accommodations_locations_on_location_id", using: :btree

  create_table "climbing_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
  end

  create_table "climbing_types_locations", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "climbing_type_id"
  end

  add_index "climbing_types_locations", ["climbing_type_id"], name: "index_climbing_types_locations_on_climbing_type_id", using: :btree
  add_index "climbing_types_locations", ["location_id"], name: "index_climbing_types_locations_on_location_id", using: :btree

  create_table "food_option_location_details", force: true do |t|
    t.integer  "location_id"
    t.integer  "food_option_id"
    t.string   "cost"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "food_option_location_details", ["food_option_id"], name: "index_food_option_location_details_on_food_option_id", using: :btree
  add_index "food_option_location_details", ["location_id"], name: "index_food_option_location_details_on_location_id", using: :btree

  create_table "food_options", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cost_ranges", array: true
  end

  create_table "grades", force: true do |t|
    t.string   "us"
    t.string   "french"
    t.string   "australian"
    t.string   "south_african"
    t.string   "uiaa"
    t.string   "uk"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "info_sections", force: true do |t|
    t.string  "title"
    t.text    "body"
    t.json    "metadata"
    t.integer "location_id"
  end

  add_index "info_sections", ["location_id"], name: "index_info_sections_on_location_id", using: :btree

  create_table "locations", force: true do |t|
    t.string   "continent"
    t.string   "name"
    t.integer  "grade_id"
    t.float    "latitude",                     default: 1.0
    t.float    "longitude",                    default: 1.0
    t.integer  "price_range_floor_cents",      default: 0,     null: false
    t.string   "price_range_floor_currency",   default: "USD", null: false
    t.integer  "price_range_ceiling_cents",    default: 0,     null: false
    t.string   "price_range_ceiling_currency", default: "USD", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "home_thumb_file_name"
    t.string   "home_thumb_content_type"
    t.integer  "home_thumb_file_size"
    t.datetime "home_thumb_updated_at"
    t.string   "country"
    t.string   "slug"
    t.string   "airport_code"
    t.boolean  "active",                       default: false
    t.string   "submitter_email"
    t.string   "closest_accommodation"
    t.boolean  "walking_distance"
    t.text     "getting_in_notes"
    t.text     "accommodation_notes"
    t.text     "common_expenses_notes"
    t.text     "saving_money_tips"
  end

  add_index "locations", ["grade_id"], name: "index_locations_on_grade_id", using: :btree

  create_table "locations_seasons", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "season_id"
  end

  add_index "locations_seasons", ["location_id"], name: "index_locations_seasons_on_location_id", using: :btree
  add_index "locations_seasons", ["season_id"], name: "index_locations_seasons_on_season_id", using: :btree

  create_table "locations_transportations", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "transportation_id"
  end

  add_index "locations_transportations", ["location_id"], name: "index_locations_transportations_on_location_id", using: :btree
  add_index "locations_transportations", ["transportation_id"], name: "index_locations_transportations_on_transportation_id", using: :btree

  create_table "primary_transportations", force: true do |t|
    t.integer  "transportation_id"
    t.integer  "location_id"
    t.string   "cost"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "primary_transportations", ["location_id"], name: "index_primary_transportations_on_location_id", using: :btree
  add_index "primary_transportations", ["transportation_id"], name: "index_primary_transportations_on_transportation_id", using: :btree

  create_table "seasons", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.integer  "numerical_value"
  end

  create_table "transportations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cost_ranges", array: true
  end

  create_table "version_associations", force: true do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id", using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",      null: false
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
    t.integer  "transaction_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree

end
