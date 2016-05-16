module United
  class Api
    include HTTParty

    # debug_output $stdout

    base_uri "https://www.united.com"
    DEFAULT_PATH = "/ual/en/us/flight-search/book-a-flight/flightshopping/getflightresults/awd"

    default_timeout 20.seconds

    headers({
      "Content-Type" => "application/json; charset=utf-8",
      "Accept" => "application/json, text/javascript, */*; q=0.01",
      "Host" => "www.united.com",
      "Accept-Language" => "en-US,en;q=0.5",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:44.0) Gecko/20100101 Firefox/44.0",
      "X-Requested-With" => "XMLHttpRequest"
    })

    class ApiError < StandardError
    end

    def initialize(options)
      @local_date = options[:local_date]
      @from_airport = options[:from_airport]
      @to_airport = options[:to_airport]
      @seats = options[:seats]
      @cabin = options[:cabin] || :business
    end

    def call!
      begin
        @response = self.class.post(DEFAULT_PATH, body: request_body)
      rescue Errno::ENETUNREACH
        raise ApiError.new
      end

      unless @response.code == 200
        raise ApiError.new(@response)
      end
    end

    def parse_itineraries
      @itineraries = []

      json["data"]["Trips"].first["Flights"].each do |f|
        iti = { segments_attributes: [] }
        iti[:total_travel_time] = f["TravelMinutesTotal"]

        # First segment
        segment = {}
        segment[:from_airport] = f["Origin"]
        segment[:to_airport] = f["Destination"]

        segment[:local_departs_at] = parse_datetime(f["DepartDateTime"])
        segment[:local_arrives_at] =parse_datetime(f["DepartDateTime"])
        segment[:travel_time] = f["TravelMinutes"]

        segment[:airline_code] = f["OperatingCarrier"]
        segment[:flight_number] =f["FlightNumber"]

        segment[:aircraft] = f["EquipmentDisclosures"]["EquipmentDescription"]
        segment[:seats_searched] = @seats

        segment[:tmp_class_by_product] = {} 
        f["Products"].map do |p| 
          segment[:tmp_class_by_product][p["Index"]] = \
            if !p["BookingCode"].empty?
              p["DataSourceLabelStyle"]
            else
              nil
            end
        end
        
        # debugger if segment[:flight_number].to_i == 433

        iti[:segments_attributes] << segment

        # Other segments
        if f["Connections"]
          f["Connections"].each do |conn|
            segment = {}
            segment[:from_airport] = conn["Origin"]
            segment[:to_airport] = conn["Destination"]

            segment[:local_departs_at] = parse_datetime(conn["DepartDateTime"])
            segment[:local_arrives_at] = parse_datetime(conn["DestinationDateTime"])
            segment[:travel_time] = conn["TravelMinutes"]

            # segment[:travel_time] = 0
            segment[:airline_code] = conn["OperatingCarrier"]
            segment[:flight_number] = conn["FlightNumber"]
            segment[:aircraft] = conn["EquipmentDisclosures"]["EquipmentDescription"]
            segment[:seats_searched] = @seats

            segment[:tmp_class_by_product] = {}
            conn["Products"].map do |p| 
              segment[:tmp_class_by_product][p["Index"]] = \
                if !p["BookingCode"].empty?
                  p["DataSourceLabelStyle"]
                else
                  nil
                end
            end

            # debugger if segment[:flight_number].to_i == 433
            iti[:segments_attributes] << segment
          end

          class_string_to_sym = {
            'Economy' => :economy,
            'Business' => :business,
            'First' => :first
          }

          saver_products = f["Products"].find_all {|p| p["AwardType"] == 'Saver' }

          if p = saver_products.find { |sp| sp["ProductType"] == "MIN-ECONOMY-SURP-OR-DISP" }
            iti[:economy_miles] = p["Prices"].first["Amount"].to_i
            iti[:economy_usd] = p["TaxAndFees"]["Amount"]

            iti[:segments_attributes].each do |s|
              class_string = s[:tmp_class_by_product][p["Index"]]
              field_name = "#{class_string_to_sym[class_string]}_available".to_sym
              s[field_name] = true
            end
          end

          if p = saver_products.find { |sp| sp["ProductType"] == "BUSINESS-SURPLUS" }
            iti[:business_miles] = p["Prices"].first["Amount"].to_i
            iti[:business_usd] = p["TaxAndFees"]["Amount"]

            iti[:segments_attributes].each do |s|
              class_string = s[:tmp_class_by_product][p["Index"]]
              field_name = "#{class_string_to_sym[class_string]}_available".to_sym
              s[field_name] = true
            end
          end

          if p = saver_products.find { |sp| sp["ProductType"] == "FIRST-SURPLUS" }
            iti[:first_miles] = p["Prices"].first["Amount"].to_i
            iti[:first_usd] = p["TaxAndFees"]["Amount"]

            iti[:segments_attributes].each do |s|
              class_string = s[:tmp_class_by_product][p["Index"]]
              field_name = "#{class_string_to_sym[class_string]}_available".to_sym
              s[field_name] = true
            end
          end
        end

        # Delete temp field
        iti[:segments_attributes].map { |s| s.delete(:tmp_class_by_product) }
        @itineraries << iti
      end

      @itineraries
    end

    def date_param
      @local_date.strftime('%b %d, %Y')
    end

    def parse_datetime(dt)
      Time.use_zone('UTC') do
        DateTime.strptime(dt, "%m/%d/%Y %H:%M")
      end
    end

    CABIN_MAPPING = {
      economy:  [ 'ECONOMY', 0 ],
      business: [ 'BUSINESS', 1 ],
      first:    [ 'FIRST', 2 ]
    }

    def cabin_param
      CABIN_MAPPING[@cabin][0]
    end

    def cabin_type_param
      CABIN_MAPPING[@cabin][1]      
    end
    
    def json
      @json ||= JSON.parse(@response.body)
    end

    def flights
      
    end

    private

    def request_body
      {
         "Origin" => @from_airport,
         "Destination" => @to_airport,
         "DepartDate" => date_param,
         "awardTravel" => true,
         "numberOfTravelers" => @seats,
         "numOfAdults" => @seats,
         "travelerCount" => @seats,
         "Trips" => [
            {
               "DepartDate" => date_param,
               "Destination" => @to_airport,
               "Origin" => @from_airport
            }
         ],
         "cabinSelection" => cabin_param,
         "awardCabinType" => cabin_type_param
      }.to_json
    end

  end
end