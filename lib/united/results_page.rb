module United
  class ResultsPage

    def initialize
      
    end

    def set_options(options={})
      @options = options

      @from_airport = options[:from_airport] if options[:from_airport]
      @to_airport = options[:to_airport] if options[:to_airport]
      @date = options[:date] if options[:date]
      @cabin = options[:cabin] if options[:cabin]
      @adults = options[:adults] if options[:adults]
    end

    def set_default_options
      @from_airport = 'ORD'  
      @to_airport = 'CPH'
      @date = Date.new(2015, 06, 21)
      @cabin = 'Business'
      @seats = 2
    end

    def search_to_s
      "#{@date.to_s} #{@from_airport} > #{@to_airport}"
    end

    def load_results
      begin
        puts "Searching #{search_to_s}"
        load_form
        enter_form_values
        submit_form
        parse_results
      rescue
        @results_page.open_in_browser if @results_page
        raise
      end
    end

    def save_results
      premium_itineraries = @itineraries.select { |i| i.business_miles or i.first_miles }
      attrs = united_search_attributes.merge(itineraries: premium_itineraries)

      UnitedSearch.new(attrs).save!
    end

    def united_search_attributes
      { 
        from_airport: @from_airport,
        to_airport: @to_airport,
        local_date: @date,
        seats: @seats
      }
    end

    def load_form
      return @form if @form

      page = Mechanize.new.get('https://www.united.com/web/en-US/apps/booking/flight/searchOW.aspx?CS=N')
      @form = page.forms.first

      unless @form
        raise "can't find form on search page"
      end
    end
      
    def enter_form_values
      from_field = @form.fields_with(name: 'ctl00$ContentInfo$SearchForm$Airports1$Origin$txtOrigin').first
      raise "can't find 'from' field" unless from_field
      from_field.value = @from_airport

      destination_field = @form.fields_with(name: 'ctl00$ContentInfo$SearchForm$Airports1$Destination$txtDestination').first
      raise "can't find 'destination' field" unless destination_field
      destination_field.value = @to_airport

      date_field1 = @form.fields_with(name: 'ctl00$ContentInfo$SearchForm$DateTimeCabin1$Depdate1$txtDptDate').first
      raise "can't find 'date1' field" unless date_field1
      date_field1.value = @date.strftime('%m/%d/%Y')

      date_field = @form.fields_with(name: 'ctl00$ContentInfo$SearchForm$DateTimeCabin1$Depdate$txtDptDate').first
      raise "can't find 'date' field" unless date_field
      date_field.value = @date.strftime('%m/%d/%Y')

      cabin_select = @form.fields_with(name: 'ctl00$ContentInfo$SearchForm$DateTimeCabin1$Cabins$cboCabin').first
      raise "can't find 'cabin' field" unless cabin_select
      cabin_select.value = @cabin

      adults_select = @form.fields_with(name: 'ctl00$ContentInfo$SearchForm$paxSelection$Adults$cboAdults').first
      raise "can't find 'adult' field" unless adults_select
      adults_select.value = @seats

      # award search
      reward_radio = @form.radiobutton_with(name: 'ctl00$ContentInfo$SearchForm$searchBy$SearchBy', value: 'rdosearchby3')
      raise "can't find 'reward' radio" unless reward_radio
      reward_radio.check
    end

    def submit_form
      submit_button = @form.buttons_with(name: 'ctl00$ContentInfo$SearchForm$searchbutton').first
      @results_page = @form.submit(submit_button)
    end

    def parse_results    
      @itineraries = [ ]

      @results_page.search('table.rewardResults > tr').each do |tr_row|
        if itinerary = parse_itinerary_row(tr_row)
          @itineraries << itinerary
        end
      end
    end


    def parse_itinerary_row(tr_row)
      if !tr_row.attributes['id'].nil?
        # headers on page
        return nil
      end

      itinerary_attributes = { segments_attributes: [] }

      coach_saver_td, coach_standard_td, business_saver_td, business_standard_td, first_saver_td, first_standard_td = tr_row.search('td.tdRewardPrice')

      itinerary_attributes[:economy_miles],  itinerary_attributes[:economy_usd]  = parse_price_td(coach_saver_td)
      itinerary_attributes[:business_miles], itinerary_attributes[:business_usd] = parse_price_td(business_saver_td)
      itinerary_attributes[:first_miles],    itinerary_attributes[:first_usd]    = parse_price_td(first_saver_td)

      tr_row.search('.tdSegmentBlock tr').each do |segment_tr|
        if segment_attrs = parse_segment_tr(segment_tr)
          itinerary_attributes[:segments_attributes] << segment_attrs
        end
      end

      travel_time_str = tr_row.search('.tdSegmentBlock .tdTrvlTime span.PHead').first.content.strip
      itinerary_attributes[:total_travel_time] = parse_travel_time(travel_time_str)

      Itinerary.new(itinerary_attributes)
    end

    def parse_price_td(price_td)
      return nil unless price_td

      content = price_td.content.strip.gsub(/\s+/, ' ').gsub(',','')

      if content == 'NotAvailable'
        return :na
      else
        match_data = content.match(/(\d+) Miles and \$(\d+\.\d+)/)
        miles = match_data[1]
        usd = match_data[2]
        [ miles.to_i, usd.to_f ]
      end
    end

    def parse_segment_tr(segment_tr)
      attrs = {}

      if td_depart = segment_tr.search('.tdDepart').first
        time_str = td_depart.elements[1].content
        date_str = td_depart.elements[2].content
        attrs[:local_departs_at] = Time.parse("#{date_str} #{time_str}").to_s(:db)
        attrs[:local_date] = Date.parse(date_str)

        airport_str = td_depart.elements[3].content
        if match = airport_str.match(/\(([A-Z]{3,4})(\s.*)?\)/)
          attrs[:from_airport] = match[1]
        end

      else
        # not a segment
        return nil
      end

      if td_arrive = segment_tr.search('.tdArrive').first
        time_str = td_arrive.elements[1].content
        date_str = td_arrive.elements[2].content
        attrs[:local_arrives_at] =Time.parse("#{date_str} #{time_str}").to_s(:db)

        airport_str = td_arrive.elements[3].content
        if match = airport_str.match(/\(([A-Z]{3,4})(\s.*)?\)/)
          attrs[:to_airport] = match[1]
        end
      end

      if travel_time_str = segment_tr.search('.tdTrvlTime').first.content
        attrs[:travel_time] = parse_travel_time(travel_time_str)

      elsif travel_time_str = segment_tr.search('.tdTrvlTime span.PHead').first.content
        attrs[:travel_time] = parse_travel_time(travel_time_str)
      end
    
      if td_segment_dtl = segment_tr.search('.tdSegmentDtl').first
        td_segment_dtl.search('div').each do |div|
          content = div.content.strip
          
          if match = content.match(/Flight:\s?([A-Z]{2})(\d+)/)
            attrs[:airline_code] = match[1]
            attrs[:flight_number] = match[2]

          elsif match = content.match(/Aircraft: (.+)/)
            attrs[:aircraft] = match[1]
          end
        end
      end

      attrs
    rescue
      puts "Failed parsing flight html: #{segment_tr.to_s}"
      raise
    end


    def parse_travel_time(travel_time_str)
      original_travel_time_str = travel_time_str.dup
      travel_time_str = travel_time_str.strip.downcase

      if match = travel_time_str.match(/flight time:(.*)\s*travel time(.*)/)
        # both times are returned
        travel_time_str = match[1]
      end

      travel_time_str = travel_time_str.gsub('flight time:', '')
      travel_time_str = travel_time_str.gsub('travel time:', '')

      match = travel_time_str.match(/(\d+)(\s?hr\s?)?(\d+)?(\s?mn)?/)
      
      if match[1] and match[2] and match[3] and match[4]
        # 1 hr 15 min
        hours = match[1].to_i
        minutes = match[3].to_i
      else
        if match[2] and match[2].match('hr')
          # 1 hr
          hours = match[1].to_i
          minutes = 0
        else
          # 15 min
          hours = 0
          minutes = match[1].to_i
        end
      end

      total_minutes = hours * 60 + minutes
      total_minutes      

    rescue => ex
      debugger
      raise
    end

    def form
      @form
    end

    def flights
      @flights
    end

    def results_page
      @results_page
    end
  end
end


def search_one
  rp = United::ResultsPage.new
  rp.set_default_options

  rp.set_options({
    date: Date.parse('2015-04-10'),
    from_airport: 'LHR', 
    to_airport: 'MUC' 
  })
  rp.load_results
  rp.save_results

  rp.flights
end

STAR_ALLIANCE_TATL_ROUTE_PAIRS = [["EWR", "AMS"], ["EWR", "ARN"], ["EWR", "BCN"], ["EWR", "BFS"], ["EWR", "BHX"], ["EWR", "BRU"], ["EWR", "CDG"], ["EWR", "DUB"], ["EWR", "EDI"], ["EWR", "FCO"], ["EWR", "FRA"], ["EWR", "GLA"], ["EWR", "GVA"], ["EWR", "HAM"], ["EWR", "IST"], ["EWR", "LHR"], ["EWR", "LIS"], ["EWR", "MAD"], ["EWR", "MAN"], ["EWR", "MXP"], ["EWR", "OSL"], ["EWR", "SNN"], ["EWR", "STR"], ["EWR", "TXL"], ["EWR", "ZRH"], ["IAD", "AMS"], ["IAD", "CDG"], ["IAD", "DUB"], ["IAD", "BRU"], ["IAD", "MAN"], ["IAD", "FCO"], ["IAD", "FRA"], ["IAD", "GVA"], ["IAD", "LHR"], ["IAD", "MUC"], ["IAD", "ZRH"], ["IAD", "MAD"], ["ORD", "AMS"], ["ORD", "BRU"], ["ORD", "CDG"], ["ORD", "FRA"], ["ORD", "LHR"], ["ORD", "MUC"], ["ORD", "EDI"], ["ORD", "SNN"], ["IAH", "AMS"], ["IAH", "FRA"], ["IAH", "LHR"], ["IAH", "MUC"], ["SFO", "CDG"], ["SFO", "FRA"], ["SFO", "LHR"], ["LAX", "LHR"], ["IAD", "VIE"], ["JFK", "VIE"], ["ORD", "VIE"], ["YYZ", "VIE"], ["IAD", "IST"], ["IAH", "IST"], ["ORD", "IST"], ["JFK", "IST"], ["LAX", "IST"], ["YYZ", "IST"], ["SFO", "IST"], ["BOS", "ZRH"], ["JFK", "ZRH"], ["LAX", "ZRH"], ["MIA", "ZRH"], ["ORD", "ZRH"], ["SFO", "ZRH"], ["YUL", "ZRH"], ["JFK", "GVA"], ["YUL", "GVA"], ["YYZ", "GVA"], ["JFK", "BRU"], ["IAD", "WAW"], ["JFK", "WAW"], ["ORD", "WAW"], ["YYZ", "WAW"], ["ATL", "FRA"], ["BOS", "FRA"], ["DEN", "FRA"], ["DFW", "FRA"], ["DTW", "FRA"], ["JFK", "FRA"], ["LAX", "FRA"], ["MCO", "FRA"], ["MEX", "FRA"], ["MIA", "FRA"], ["PHL", "FRA"], ["SEA", "FRA"], ["YVR", "FRA"], ["YYZ", "FRA"], ["YUL", "FRA"], ["BOS", "MUC"], ["CLT", "MUC"], ["EWR", "MUC"], ["JFK", "MUC"], ["LAX", "MUC"], ["SFO", "MUC"], ["YUL", "MUC"], ["YVR", "MUC"], ["MEX", "MUC"], ["MIA", "MUC"], ["YYZ", "MUC"], ["EWR", "DUS"], ["ORD", "DUS"], ["EWR", "CPH"], ["IAD", "CPH"], ["ORD", "CPH"], ["SFO", "CPH"], ["ORD", "ARN"], ["IAH", "SVG"], ["MIA", "LIS"], ["EWR", "OPO"], ["MIA", "OPO"], ["IAH", "DME"], ["YYZ", "CPH"], ["YYZ", "LHR"], ["YYZ", "MXP"], ["YYZ", "CDG"], ["YYZ", "TLV"], ["YYZ", "ZRH"], ["YYZ", "MAD"], ["YYZ", "FCO"], ["YYZ", "DUB"], ["YYZ", "ATH"], ["YYZ", "BCN"], ["YYZ", "EDI"], ["YYZ", "VCE"], ["YYZ", "MAN"], ["YYZ", "LIS"], ["YUL", "BRU"], ["YUL", "LHR"], ["YUL", "CDG"], ["YUL", "FCO"], ["YUL", "ATH"], ["YUL", "BCN"], ["YUL", "NCE"], ["YYC", "LHR"], ["YYT", "LHR"], ["YEG", "LHR"], ["YHZ", "LHR"], ["YOW", "LHR"], ["YYC", "FRA"], ["YOW", "FRA"]]


def search_all_routes(options)
  if options[:date]
    dates = [ Date.parse(options[:date]) ]
  else
    dates = [Date.parse('2015-06-20'), Date.parse('2015-06-21') ]
  end

  dates.each do |date|
    STAR_ALLIANCE_TATL_ROUTE_PAIRS.each do |from_airport, to_airport|
      rp = United::ResultsPage.new
      rp.set_default_options
      rp.set_options({
        date: date,
        from_airport: from_airport, 
        to_airport: to_airport
      })
debugger
      rp.load_results
      rp.save_results
    end
  end
end

def search_many  
  # from_airports = [ 'LAX', 'SFO', 'ORD', 'IAH' ]
  # from_airports = [ 'SFO', 'LAX', 'ORD', 'EWR', 'IAH' ]
  from_airports = [ 'KIX', 'NRT', 'HND' ]
  to_airports = %w/SIN BKK/
  from_date = Date.parse '2015-12-07'
  to_date = Date.parse '2015-12-11'


  from_airports.each do |from_airport|
    to_airports.each do |to_airport|
      (from_date..to_date).each do |date|
        next if from_airport == to_airport

        rp = United::ResultsPage.new
        rp.set_default_options
        rp.set_options({
          date: date,
          from_airport: from_airport, 
          to_airport: to_airport
        })

        rp.load_results
        rp.save_results
      end
    end
  end

end