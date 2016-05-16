module BA
  class ResultsPage

    def initialize
      
    end

    def set_options(options={})
      @options = options

      @from_airport = options[:from_airport] if options[:from_airport]
      @to_airport = options[:to_airport] if options[:to_airport]
      @date = options[:date] if options[:date]
      
      @cabin = 
        case options[:cabin]
        when :economy
          'M'
        when :premium_economy
          'W'
        when :business
          'C'
        when :first
          'F'
        end

      @cabin = options[:cabin] if options[:cabin]
      @seats = options[:seats] if options[:seats]
    end

    def set_default_options
      @from_airport = 'JFK'  
      @to_airport = 'LHR'
      @date = Date.new(2015, 8, 21)
      @cabin = 'C' # business
      @seats = 2
    end

    def search_to_s
      "#{@date.to_s} #{@from_airport} > #{@to_airport}"
    end

    def validate_search!
      raise "Missing: from_airport" unless @from_airport
      raise "Missing: to_airport"   unless @to_airport
      raise "Missing: date"         unless @date
      raise "Missing: cabin"        unless @cabin
      raise "Missing: seats"        unless @seats
    end

    def load_results
      begin
        puts "Searching #{search_to_s}"
        validate_search!

        load_search_form
        enter_form_values
        submit_form
      debugger
        parse_results
      rescue
        @results_page.open_in_browser if @results_page
        raise
      end
    end

    def save_results
      # premium_itineraries = @itineraries.select { |i| i.business_miles or i.first_miles }
      attrs = search_attributes.merge(itineraries: @itineraries)

      UnitedSearch.import(attrs)
    end

    def search_attributes
      { 
        from_airport: @from_airport,
        to_airport: @to_airport,
        local_date: @date,
        seats: @seats
      }
    end

    def load_search_page
      return @search_page if @search_page

      print "logging in... "
      @login_page = Mechanize.new.get('https://www.britishairways.com/travel/redeem/execclub/_gf/en_us?eId=106019&tab_selected=redeem&redemption_type=STD_RED')
      @login_form = @login_page.form_with(name: 'toploginform')

      membership_number_field = @login_form.fields_with(name: 'membershipNumber').first
      raise "can't find 'membershipNumber' field" unless membership_number_field
      membership_number_field.value = '97736164'

      password_field = @login_form.fields_with(name: 'password').first
      raise "can't find 'password' field" unless password_field
      password_field.value = 'GaTDeC7T'

      remember_checkbox = @login_form.checkbox_with(name: 'rememberLogin')
      raise "can't find 'remember' checkbox" unless remember_checkbox
      remember_checkbox.check

debugger
      submit_button = @login_form.buttons_with(class: 'secondary').first
      @search_page = @login_form.submit(submit_button)

      puts "done"

      @search_page
    end

    def load_search_form
      return @form if @form

      page = load_search_page
      debugger
      @form = page.form_with(id: 'plan_redeem_trip')

      unless @form
        raise "can't find form on search page"
      end
    end
      
    def enter_form_values
      from_field = @form.field_with(name: 'departurePoint')
      raise "can't find 'from' field" unless from_field
      from_field.value = @from_airport

      destination_field = @form.field_with(name: 'destinationPoint')
      raise "can't find 'destination' field" unless destination_field
      destination_field.value = @to_airport

      date_field = @form.field_with(name: 'departInputDate')
      raise "can't find 'date1' field" unless date_field
      date_field.value = @date.strftime('%m/%d/%Y')

      oneway_checkbox = @form.checkbox_with(name: 'oneWay')
      raise "can't find 'oneWay' checkbox" unless oneway_checkbox
      oneway_checkbox.check

      cabin_select = @form.field_with(id: 'cabin')
      raise "can't find 'cabin' field" unless cabin_select
      cabin_select.value = @cabin

      adults_select = @form.field_with(name: 'NumberOfAdults')
      raise "can't find 'adult' field" unless adults_select
      adults_select.value = @seats
    end

    def submit_form
      submit_button = @form.buttons_with(id: 'submitBtn').first
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



      # segments
      tr_row.search('.tdSegmentBlock tr').each do |segment_tr|
        if segment_attrs = parse_segment_tr(segment_tr)
          segment_attrs[:cabins_available] = []
          itinerary_attributes[:segments_attributes] << segment_attrs
        end
      end

      travel_time_str = tr_row.search('.tdSegmentBlock .tdTrvlTime span.PHead').first.content.strip
      itinerary_attributes[:total_travel_time] = parse_travel_time(travel_time_str)



      # price
      coach_saver_td, coach_standard_td, business_saver_td, business_standard_td, first_saver_td, first_standard_td = tr_row.search('td.tdRewardPrice')
      
      economy_price = parse_price_td(coach_saver_td)
      if economy_price != :na
        itinerary_attributes[:economy_miles] = economy_price[:miles]
        itinerary_attributes[:economy_usd] = economy_price[:usd]

        itinerary_attributes[:segments_attributes].each do |segment_attribute|
          segment_attribute[:cabins_available] << :economy
        end
      end


      if business_price = parse_price_td(business_saver_td)
        if business_price != :na
          itinerary_attributes[:business_miles] = business_price[:miles]
          itinerary_attributes[:business_usd] = business_price[:usd]

          itinerary_attributes[:segments_attributes].each do |segment_attribute|
            if business_price[:segment_mixed_cabins].any?
              actual_cabin = business_price[:segment_mixed_cabins][segment_attribute[:segment_code]]
              segment_attribute[:cabins_available] << actual_cabin
            else
              segment_attribute[:cabins_available] << :business
            end
          end
        end
      end        

      if first_price = parse_price_td(first_saver_td)
        if first_price != :na
          debugger if itinerary_attributes.nil?
          debugger if first_price.nil?
          itinerary_attributes[:first_miles] = first_price[:miles]
          itinerary_attributes[:first_usd] = first_price[:usd]

          itinerary_attributes[:segments_attributes].each do |segment_attribute|
            if first_price[:segment_mixed_cabins].any?
              actual_cabin = first_price[:segment_mixed_cabins][segment_attribute[:segment_code]]
              segment_attribute[:cabins_available] << actual_cabin
            else
              segment_attribute[:cabins_available] << :first
            end
          end
        end
      end

      # dedupe cabins_available & set seats
      itinerary_attributes[:segments_attributes].each do |segment_attributes|
        segment_attributes[:cabins_available].uniq!
        segment_attributes[:seats_searched] = @seats
      end

      itinerary_attributes
    end

    def parse_price_td(price_td)
      return nil unless price_td

      segment_mixed_cabins = {}

      if mixed_cabin_div = price_td.search('.divMixedCabin').first
        mixed_cabin_div_str = mixed_cabin_div.attributes['title'].value
        mixed_cabin_div_str.split('|').each do |segment_cabin_str|
          actual_cabin, reason = segment_cabin_str.split(',')
          flight_description, cabin_description = actual_cabin.split('---')
          segment_code = flight_description.split(' ').first

          cabin = case cabin_description 
                  when 'Economy', 'United Economy'
                    :economy
                  when 'Business', 'United Business', 'United BusinessFirst'
                    :business
                  when 'First', 'United Global First', 'United First'
                    :first
                  else
                    raise "Dont know cabin description: #{cabin_description}"
                  end

          segment_mixed_cabins[segment_code] = cabin
        end
      end

      content = price_td.content.strip.gsub(/\s+/, ' ').gsub(',','')

      if content == 'NotAvailable'
        return :na
      else
        match_data = content.match(/(\d+) Miles and \$(\d+\.\d+)/)
        miles = match_data[1]
        usd = match_data[2]

        { 
          miles: miles.to_i,
          usd: usd.to_i,
          segment_mixed_cabins: segment_mixed_cabins
        }
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
            attrs[:segment_code] = "#{match[1]}#{match[2]}"

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




if false
  rp = BA::ResultsPage.new

  rp.set_options({
    date: Date.parse('2015-07-01'),
    from_airport: 'SFO', 
    to_airport: 'LAX',
    seats: 2,
    cabin: :business
  })

  rp.load_results
  # rp.save_results
end



