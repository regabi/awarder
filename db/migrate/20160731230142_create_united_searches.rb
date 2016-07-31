class CreateUnitedSearches < ActiveRecord::Migration
  def change
    create_table :united_searches do |t|
      t.date :local_date
      t.string :from_airport, length: 4
      t.string :to_airport, length: 4
      t.integer :seats
      t.timestamps
    end
  end
end
