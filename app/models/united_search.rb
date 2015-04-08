class UnitedSearch < ActiveRecord::Base

  has_many :itineraries, :foreign_key => 'search_id'
  accepts_nested_attributes_for :itineraries

end
