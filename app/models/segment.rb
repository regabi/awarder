class Segment < ActiveRecord::Base

  has_and_belongs_to_many :itineraries
  after_initialize :set_date

  def set_date
    self.local_date = local_departs_at.to_date
  end

  def self.get(attributes)
    puts "Look up: #{attributes}"

    unless local_date = attributes[:local_date]
      local_date = attributes[:local_departs_at].to_date
    end

    if segment = Segment.where({
        from_airport:  attributes[:from_airport], 
        local_date:    local_date,
        airline_code:  attributes[:airline_code],
        flight_number: attributes[:flight_number]
      }).first

      puts "Found: #{segment.attributes}"
      return segment
    end

    segment = Segment.create(attributes)
    puts "Created: #{segment.attributes}"
    segment
  end

end
