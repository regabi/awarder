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
      @adults = 2
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
      @flights.each do |f|
        f.save_if_premium_class!
      end
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
      adults_select.value = @adults

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
      @flights = [ ]

      @results_page.search('table.rewardResults > tr').each do |tr_row|
        if flight = parse_flight_row(tr_row)
          @flights << flight
        end
      end
    end


    def parse_flight_row(tr_row)
      if !tr_row.attributes['id'].nil?
        # headers on page
        return nil
      end

      attrs = {}

      coach_saver_td, coach_standard_td, business_saver_td, business_standard_td, first_saver_td, first_standard_td = tr_row.search('td.tdRewardPrice')

      attrs[:coach_saver_miles],    attrs[:coach_saver_usd]    = parse_price_td(coach_saver_td)
      attrs[:business_saver_miles], attrs[:business_saver_usd] = parse_price_td(business_saver_td)
      attrs[:first_saver_miles],    attrs[:first_saver_usd]    = parse_price_td(first_saver_td)

      attrs[:segments_attributes] = []

      position = 1
      tr_row.search('.tdSegmentBlock tr').each do |segment_tr|
        if segment_attrs = parse_segment_tr(segment_tr, position)
          segment_attrs[:position] = position
          attrs[:segments_attributes] << segment_attrs
          position += 1
        end
      end

      travel_time_str = tr_row.search('.tdSegmentBlock .tdTrvlTime span.PHead').first.content.strip
      attrs[:total_travel_time] = parse_travel_time(travel_time_str)

      Flight.new(attrs)
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

    def parse_segment_tr(segment_tr, position)
      attrs = {}

      if td_depart = segment_tr.search('.tdDepart').first
        time_str = td_depart.elements[1].content
        date_str = td_depart.elements[2].content
        attrs[:local_departs_at] = Time.parse("#{date_str} #{time_str}")

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
        attrs[:local_arrives_at] =Time.parse("#{date_str} #{time_str}")

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

      attrs[:position] = position
      attrs
    rescue
      puts "Failed parsing flight row position: #{position}"
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


if false

  rp = United::ResultsPage.new
  rp.set_default_options
  rp.set_options(:to_airport => 'LHR')
  rp.load_results
  rp.save_results

  rp.flights
end


def search_many
  
  # from_airports = [ 'LAX', 'SFO', 'ORD', 'IAH' ]
  # from_airports = [ 'SFO', 'LAX', 'ORD', 'EWR', 'IAH' ]
  from_airports = [ 'SFO', 'LAX' ]
  to_airports = %w/NRT ICN HKG/
  from_date = Date.parse '2015-04-09'
  to_date = Date.parse '2015-04-15'


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