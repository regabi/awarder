class Segment < ActiveRecord::Base

  after_initialize :set_date

  has_many :itineraries_segments, :class_name => 'ItinerariesSegments'
  has_many :itineraries, :through => :itineraries_segments

  attr_accessor :cabins_available, :segment_code

  def cabins_available=(cabins_available)
    unless new_record?
      # updated over 24 hours ago, clear availability
      if updated_at < 24.hours.ago
        self.economy_available = nil
        self.premium_economy_available = nil
        self.business_available = nil
        self.first_available = nil
      end
    end

    # otherwise, just add new availibility, dont clear it
    %w/economy premium_economy business first/.each do |cabin|
      if cabins_available.include?(cabin.to_sym)
        self.send("#{cabin}_available=", true)
      end
    end
  end

  def set_date
    self.local_date = local_departs_at.to_date
  end

  def self.get(attributes)
    attributes[:updated_at] = Time.now

    unless local_date = attributes[:local_date]
      local_date = attributes[:local_departs_at].to_date
    end

    print "[#{local_date}] #{attributes[:airline_code]} #{attributes[:flight_number]} #{attributes[:from_airport]} > #{attributes[:to_airport]} "
    # print " #{attributes[:cabins_available].join(', ')} "
    print " economy" if attributes[:economy_available]
    print " premium_economy" if attributes[:premium_economy_available]
    print " business" if attributes[:business_available]
    print " first" if attributes[:first_available]

    if segment = Segment.where({
        from_airport:  attributes[:from_airport], 
        local_date:    local_date,
        airline_code:  attributes[:airline_code],
        flight_number: attributes[:flight_number]
      }).first

      puts ""

      segment.update_attributes(attributes)
      
      return segment
    end


    segment = Segment.create(attributes)
    puts ""
    segment
  end

  def to_s
    "[#{local_date}] #{airline_code} #{flight_number} #{from_airport} > #{to_airport}"
  end

end
