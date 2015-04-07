class Segment < ActiveRecord::Base
  belongs_to :flight

  after_initialize :set_date
  before_save :delete_if_already_there

  def set_date
    self.local_date = local_departs_at.to_date
  end

  def delete_if_already_there
    Segment.where(from_airport: from_airport, local_date: local_date, airline_code: airline_code, flight_number: flight_number).delete_all
    return true
  end

end
