class CreateFlights < ActiveRecord::Migration
  def change
    create_table :flights do |t|
      t.string :from_airport
      t.string :to_airport

      t.datetime :local_departs_at
      t.datetime :local_arrives_at

      t.integer :coach_saver_miles
      t.float   :coach_saver_usd
      t.integer :business_saver_miles
      t.float   :business_saver_usd
      t.integer :first_saver_miles
      t.float   :first_saver_usd

      t.integer :total_travel_time
      
      t.timestamps null: false
    end
  end
end
