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

ActiveRecord::Schema.define(version: 20150326235854) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accommodations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
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
    t.string   "latitude"
    t.string   "longitude"
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
  end

  add_index "locations", ["grade_id"], name: "index_locations_on_grade_id", using: :btree

  create_table "locations_seasons", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "season_id"
  end

  add_index "locations_seasons", ["location_id"], name: "index_locations_seasons_on_location_id", using: :btree
  add_index "locations_seasons", ["season_id"], name: "index_locations_seasons_on_season_id", using: :btree

  create_table "seasons", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
  end

end
