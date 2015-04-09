class ItinerariesSegments < ActiveRecord::Base

  belongs_to :itinerary
  belongs_to :segment

  default_scope { order 'position' }
  acts_as_list scope: :itinerary
end