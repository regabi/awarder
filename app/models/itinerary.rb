class Itinerary < ActiveRecord::Base

  # has_many :itineraries_segments
  # has_many :segments, :through => :itineraries_segments
  
  has_and_belongs_to_many :segments
  accepts_nested_attributes_for :segments

  before_validation :set_attributes_from_segments

  belongs_to :search, :class_name => 'UnitedSearch', :primary_key => 'search_id'

  def segments_attributes=(segments_attributes)
    segments_attributes.each_with_index do |attrs|
      self.segments << Segment.get(attrs)
    end

    super([])
  end

  def set_attributes_from_segments
    self.from_airport = segments.first.from_airport
    self.to_airport = segments.last.to_airport

    self.local_departs_at = segments.first.local_departs_at
    self.local_arrives_at = segments.last.local_arrives_at

    self.local_date = segments.first.local_departs_at.to_date
  end

end
