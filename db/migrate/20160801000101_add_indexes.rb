class AddIndexes < ActiveRecord::Migration
  def change
    add_index :segments, [ :local_date, :airline_code, :flight_number ]
    add_index :itineraries, :segment_ids_cache
    add_index :itineraries_segments, :itinerary_id
  end
end
