class Flight < ActiveRecord::Base

  has_many :segments
  accepts_nested_attributes_for :segments

  after_initialize :set_attributes_from_segments


  def set_attributes_from_segments
    self.from_airport = segments.first.from_airport
    self.to_airport = segments.last.to_airport

    self.local_departs_at = segments.first.local_departs_at
    self.local_arrives_at = segments.last.local_arrives_at

    self.local_date = segments.first.local_departs_at.to_date
  end
end
