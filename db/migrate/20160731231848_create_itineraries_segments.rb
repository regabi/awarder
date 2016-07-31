class CreateItinerariesSegments < ActiveRecord::Migration
  def change
    
    create_table "itineraries_segments", force: :cascade do |t|
      t.integer  "itinerary_id", limit: 4
      t.integer  "segment_id",   limit: 4
      t.integer  "position",     limit: 4
      t.datetime "updated_at"
      t.datetime "created_at"
    end

  end
end
