require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'

Capybara.default_driver = :poltergeist
Capybara.run_server = false

module AA
  class ResultsPage
    include Capybara::DSL

    def set_options(options={})
      @options = options

      @from_airport = options[:from_airport] if options[:from_airport]
      @to_airport = options[:to_airport] if options[:to_airport]
      @date = options[:date] if options[:date]
      @cabin = options[:cabin] if options[:cabin]
      @seats = options[:seats] if options[:seats]
    end

    def load_results
      begin
        puts "Searching #{search_to_s}"
        validate_search!

        load_form
        enter_form_values
        submit_form
        parse_results
      rescue
        @results_page.open_in_browser if @results_page
        raise
      end
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

    def load_form
      return @form if @form

      visit('http://www.aa.com/reservation/awardFlightSearchAccess.do')
      # page = Nokogiri::HTML(self.page.html)
      # page.forms[2]

      # page = Mechanize.new.get('http://www.aa.com/reservation/awardFlightSearchAccess.do')
      # @form = page.forms[2]

      # unless @form
      #   raise "can't find form on search page"
      # end
    end
      
    def enter_form_values
      # # one way
      # one_way_radio = @form.radiobuttons_with(name: 'tripType', value: 'oneWay').first
      # raise "can't find 'one_way' radio field" unless one_way_radio
      # one_way_radio.check
      page.choose "One-Way"

      # # exact date
      # exact_date_radio = @form.radiobuttons_with(name: 'awardDatesFlexible', value: 'false').first
      # raise "can't find 'exact_date' radio field" unless exact_date_radio
      # exact_date_radio.check
      page.choose "Exact Dates"

      # from_field = @form.fields_with(name: 'originAirport').first
      # raise "can't find 'from' field" unless from_field
      # from_field.value = @from_airport
      page.fill_in('originAirport', with: @from_airport)

      # destination_field = @form.fields_with(name: 'destinationAirport').first
      # raise "can't find 'destination' field" unless destination_field
      # destination_field.value = @to_airport
      page.fill_in('destinationAirport', with: @to_airport)

      # month_select = @form.fields_with(name: 'flightParams.flightDateParams.travelMonth').first
      # raise "can't find 'month_select' field" unless month_select
      # month_select.value = @date.month
      page.select(@date.strftime('%b'), from: 'flightParams.flightDateParams.travelMonth')

      # day_select = @form.fields_with(name: 'flightParams.flightDateParams.travelDay').first
      # raise "can't find 'day_select' field" unless day_select
      # day_select.value = @date.day
      page.select(@date.day, from: 'flightParams.flightDateParams.travelDay')

      # cabin_select = @form.fields_with(name: 'awardCabinClass').first
      # raise "can't find 'cabin' field" unless cabin_select
      
      cabin_for_form = case @cabin.downcase
                        when 'economy'
                          'E'
                        when 'business'
                          'B'
                        when 'first'
                          'P'
                        end

      page.select(cabin_for_form, from: 'awardCabinClass')
      # cabin_select.value = cabin_for_form


      # adults_select = @form.fields_with(name: 'adultPassengerCount').first
      # raise "can't find 'adult' field" unless adults_select
      # adults_select.value = @seats
      page.select(@seats, from: 'awardFlightSearchForm.adultPassengerCount')

    rescue
      self.page.open_in_browser
      raise
    end

    def submit_form
      # submit_button = @form.buttons_with(value: 'Continue').first
      # @results_page = @form.submit(submit_button)
      print "submitting..."
      page.click_button('Continue')
      puts "Done"
    end

    def parse_results
      # wait
      if has_css?("div.aa_flightListContainerBot")
        puts "** TRUE"
      else
        puts "** FALSE"
      end

      @results_page = Nokogiri::HTML(self.page.html)
      @itineraries = [ ]
    
# @results_page.open_in_browser
      @results_page.search('div.aa_flightListContainerBot').each do |itinerary_div|
        if itinerary = parse_itinerary(itinerary_div)
          @itineraries << itinerary
        end
      end
    end

    def parse_itinerary(div)
      itinerary_attributes = { segments_attributes: [] }

      div.search('.ca_flightSlice').each do |segment_div|
        debugger
        segment_code = segment_div.search('.aa_flightList_col-2').first.content.strip

        if segment_code.to_i.to_s == segment_code
          # AA flight
          attrs[:airline_code] = 'AA'
          attrs[:flight_number] = segment_code.to_i

        else match = segment_code.match(/(\w{2})\s?(\d{1,4})/)
          attrs[:airline_code] = match[1]
          attrs[:flight_number] = match[2].to_i
        end

        attrs[:segment_code] = "#{attrs[:airline_code]}#{attrs[:flight_number]}"

        debugger
        true
      end


      itinerary_attributes
    end

    def save_results
      # premium_itineraries = @itineraries.select { |i| i.business_miles or i.first_miles }
      attrs = search_attributes.merge(itineraries: @itineraries)

      # AASearch.import(attrs)
    end


    def search_attributes
      { 
        from_airport: @from_airport,
        to_airport: @to_airport,
        local_date: @date,
        seats: @seats
      }
    end

  end
end


if false
  rp = AA::ResultsPage.new

  rp.set_options({
    date: Date.parse('2015-07-01'),
    from_airport: 'SFO', 
    to_airport: 'LAX',
    seats: 2,
    cabin: 'Business'
  })

  rp.load_results
  # rp.save_results
end


