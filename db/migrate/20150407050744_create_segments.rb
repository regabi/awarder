class CreateSegments < ActiveRecord::Migration
  def change
    create_table :segments do |t|
      t.string :from_airport
      t.string :to_airport

      t.string :airline_code
      t.string :flight_number

      t.datetime :local_departs_at
      t.datetime :local_arrives_at

      t.integer :travel_time
      
      t.string :aircraft

      t.timestamps null: false
    end
  end
end
