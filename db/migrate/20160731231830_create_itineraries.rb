class CreateItineraries < ActiveRecord::Migration
  def change

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

  end
end
