class AddFieldsToSegments < ActiveRecord::Migration
  def change
    # add_column :segments, :seats_searched, :integer
    add_column :segments, :economy_available, :boolean
    add_column :segments, :business_available, :boolean
    add_column :segments, :first_available, :boolean
  end
end
