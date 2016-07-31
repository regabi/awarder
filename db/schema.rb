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

ActiveRecord::Schema.define(version: 20160731231848) do

  create_table "flights", force: :cascade do |t|
    t.string   "from_airport",         limit: 255
    t.string   "to_airport",           limit: 255
    t.datetime "local_date"
    t.datetime "local_departs_at"
    t.datetime "local_arrives_at"
    t.integer  "coach_saver_miles",    limit: 4
    t.float    "coach_saver_usd",      limit: 24
    t.integer  "business_saver_miles", limit: 4
    t.float    "business_saver_usd",   limit: 24
    t.integer  "first_saver_miles",    limit: 4
    t.float    "first_saver_usd",      limit: 24
    t.integer  "total_travel_time",    limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "itineraries", force: :cascade do |t|
    t.string   "from_airport",      limit: 4
    t.string   "to_airport",        limit: 4
    t.date     "local_date"
    t.datetime "local_departs_at"
    t.datetime "local_arrives_at"
    t.integer  "total_travel_time", limit: 4
    t.integer  "economy_miles",     limit: 4
    t.integer  "business_miles",    limit: 4
    t.integer  "first_miles",       limit: 4
    t.decimal  "economy_usd",                   precision: 10, scale: 2
    t.decimal  "business_usd",                  precision: 10, scale: 2
    t.decimal  "first_usd",                     precision: 10, scale: 2
    t.string   "segment_ids_cache", limit: 255
    t.integer  "segment_ids_count", limit: 4
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "itineraries_segments", force: :cascade do |t|
    t.integer  "itinerary_id", limit: 4
    t.integer  "segment_id",   limit: 4
    t.integer  "position",     limit: 4
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "segments", force: :cascade do |t|
    t.integer  "flight_id",          limit: 4
    t.integer  "position",           limit: 4
    t.string   "from_airport",       limit: 255
    t.string   "to_airport",         limit: 255
    t.string   "airline_code",       limit: 255
    t.string   "flight_number",      limit: 255
    t.datetime "local_date"
    t.datetime "local_departs_at"
    t.datetime "local_arrives_at"
    t.integer  "travel_time",        limit: 4
    t.string   "aircraft",           limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "seats_searched",     limit: 4
    t.boolean  "economy_available",  limit: 1
    t.boolean  "business_available", limit: 1
    t.boolean  "first_available",    limit: 1
  end

  create_table "united_searches", force: :cascade do |t|
    t.date     "local_date"
    t.string   "from_airport", limit: 255
    t.string   "to_airport",   limit: 255
    t.integer  "seats",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
