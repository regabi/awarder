class UnitedSearch < ActiveRecord::Base

  has_many :itineraries, :foreign_key => 'search_id'
  accepts_nested_attributes_for :itineraries

  def self.import(attributes)
    itineraries = attributes.delete(:itineraries)

    united_search = UnitedSearch.create!(attributes)

    itineraries.each do |itinerary_attributes|
      segments = []

      segment_attributes = itinerary_attributes.delete(:segments_attributes)

      segment_attributes.each do |segment_attributes|
        segments << Segment.get(segment_attributes)
      end

      itinerary_attributes[:segment_ids] = segments.map(&:id)

      Itinerary.get(itinerary_attributes)
    end


  end

end
