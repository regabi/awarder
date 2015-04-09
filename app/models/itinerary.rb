class Itinerary < ActiveRecord::Base
  
  has_many :itineraries_segments, :class_name => 'ItinerariesSegments'
  has_many :segments, :through => :itineraries_segments
  
  accepts_nested_attributes_for :segments

  before_validation :set_attributes_from_segments
  before_save :save_segment_ids_cache

  belongs_to :search, :class_name => 'UnitedSearch', :primary_key => 'search_id'

  # def segments_attributes=(segments_attributes)
  #   segments_attributes.each_with_index do |attrs|
  #     self.segments << Segment.get(attrs)
  #   end

  #   super([])
  # end

  def self.get(attributes)
    raise "Missing segment_ids" if attributes[:segment_ids].blank?

    segment_ids_cache = attributes[:segment_ids].join(',')

    if itinerary = Itinerary.where(segment_ids_cache: segment_ids_cache).first
      itinerary.update_attributes(attributes)
      itinerary
    else
      Itinerary.create(attributes)  
    end
  end


  def save_segment_ids_cache
    self.segment_ids_cache = segment_ids.join(',')
    self.segment_ids_count = segment_ids.size
  end

  def set_attributes_from_segments
    self.from_airport = segments.first.from_airport
    self.to_airport = segments.last.to_airport

    self.local_departs_at = segments.first.local_departs_at
    self.local_arrives_at = segments.last.local_arrives_at

    self.local_date = segments.first.local_departs_at.to_date
  end

end
