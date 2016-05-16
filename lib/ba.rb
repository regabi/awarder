module BA

  # STAR_ALLIANCE_TATL_ROUTE_PAIRS = [["SFO", "CDG"], ["SFO", "FRA"], ["SFO", "LHR"], ["SFO", "MUC"], ["SFO", "ZRH"], ["SFO", "CPH"], ["SFO", "IST"], ["LAX", "LHR"], ["LAX", "IST"], ["LAX", "ZRH"], ["LAX", "FRA"], ["LAX", "MUC"], ["SEA", "FRA"], ["YVR", "FRA"], ["YVR", "MUC"], ["EWR", "AMS"], ["EWR", "ARN"], ["EWR", "BCN"], ["EWR", "BFS"], ["EWR", "BHX"], ["EWR", "BRU"], ["EWR", "CDG"], ["EWR", "DUB"], ["EWR", "EDI"], ["EWR", "FCO"], ["EWR", "FRA"], ["EWR", "GLA"], ["EWR", "GVA"], ["EWR", "HAM"], ["EWR", "IST"], ["EWR", "LHR"], ["EWR", "LIS"], ["EWR", "MAD"], ["EWR", "MAN"], ["EWR", "MXP"], ["EWR", "OSL"], ["EWR", "SNN"], ["EWR", "STR"], ["EWR", "TXL"], ["EWR", "ZRH"], ["IAD", "AMS"], ["IAD", "CDG"], ["IAD", "DUB"], ["IAD", "BRU"], ["IAD", "MAN"], ["IAD", "FCO"], ["IAD", "FRA"], ["IAD", "GVA"], ["IAD", "LHR"], ["IAD", "MUC"], ["IAD", "ZRH"], ["IAD", "MAD"], ["ORD", "AMS"], ["ORD", "BRU"], ["ORD", "CDG"], ["ORD", "FRA"], ["ORD", "LHR"], ["ORD", "MUC"], ["ORD", "EDI"], ["ORD", "SNN"], ["IAH", "AMS"], ["IAH", "FRA"], ["IAH", "LHR"], ["IAH", "MUC"], ["IAD", "VIE"], ["JFK", "VIE"], ["ORD", "VIE"], ["YYZ", "VIE"], ["IAD", "IST"], ["IAH", "IST"], ["ORD", "IST"], ["JFK", "IST"], ["YYZ", "IST"], ["BOS", "ZRH"], ["JFK", "ZRH"], ["MIA", "ZRH"], ["ORD", "ZRH"], ["YUL", "ZRH"], ["JFK", "GVA"], ["YUL", "GVA"], ["YYZ", "GVA"], ["JFK", "BRU"], ["IAD", "WAW"], ["JFK", "WAW"], ["ORD", "WAW"], ["YYZ", "WAW"], ["ATL", "FRA"], ["BOS", "FRA"], ["DEN", "FRA"], ["DFW", "FRA"], ["DTW", "FRA"], ["JFK", "FRA"], ["MCO", "FRA"], ["MEX", "FRA"], ["MIA", "FRA"], ["PHL", "FRA"], ["YYZ", "FRA"], ["YUL", "FRA"], ["BOS", "MUC"], ["CLT", "MUC"], ["EWR", "MUC"], ["JFK", "MUC"], ["YUL", "MUC"], ["MEX", "MUC"], ["MIA", "MUC"], ["YYZ", "MUC"], ["EWR", "DUS"], ["ORD", "DUS"], ["EWR", "CPH"], ["IAD", "CPH"], ["ORD", "CPH"], ["ORD", "ARN"], ["IAH", "SVG"], ["MIA", "LIS"], ["EWR", "OPO"], ["MIA", "OPO"], ["IAH", "DME"], ["YYZ", "CPH"], ["YYZ", "LHR"], ["YYZ", "MXP"], ["YYZ", "CDG"], ["YYZ", "TLV"], ["YYZ", "ZRH"], ["YYZ", "MAD"], ["YYZ", "FCO"], ["YYZ", "DUB"], ["YYZ", "ATH"], ["YYZ", "BCN"], ["YYZ", "EDI"], ["YYZ", "VCE"], ["YYZ", "MAN"], ["YYZ", "LIS"], ["YUL", "BRU"], ["YUL", "LHR"], ["YUL", "CDG"], ["YUL", "FCO"], ["YUL", "ATH"], ["YUL", "BCN"], ["YUL", "NCE"], ["YYC", "LHR"], ["YYT", "LHR"], ["YEG", "LHR"], ["YHZ", "LHR"], ["YOW", "LHR"], ["YYC", "FRA"], ["YOW", "FRA"]]
  
  def self.search(options)
    
    # routes
    if options[:routes]
      if options[:routes] == 'star_tatl'
        routes = STAR_ALLIANCE_TATL_ROUTE_PAIRS
      else
        routes = options[:routes]
      end

    elsif options[:from]
      if options[:from].is_a?(String)
        froms = [ options[:from] ]  
      else
        froms = options[:from]
      end
      
      if options[:to].is_a?(String)
        tos = [ options[:to] ]  
      else
        tos = options[:to]
      end

      routes = []
      froms.each do |from|
        tos.each do |to|
          routes << [ from, to ]
        end
      end
    end


    # dates
    if options[:date]
      dates = [ Date.parse(options[:date]) ]
    elsif options[:from_date]
      dates = (Date.parse(options[:from_date])..Date.parse(options[:to_date]))
    elsif options[:dates]
      dates = options[:dates].map { |d| Date.parse(d) }
    end



    ActiveRecord::Base.logger.level = 1
    
    routes.each do |from_airport, to_airport|
      dates.each do |date|

        rp = BA::ResultsPage.new

        rp.set_options({
          date: date,
          from_airport: from_airport, 
          to_airport: to_airport,
          seats: options[:seats],
          cabin: :business
        })

        rp.load_results
        rp.save_results

        # puts "Press Enter..."
        # a = gets.chomp

      end
    end

    
  end

end

Dir[Rails.root.to_s + "/lib/ba/*.rb"].each { |file| require(file) }


# United.search(date: '2015-04-28', routes: 'star_tatl', seats: 1)
# United.search(date: '2015-04-28', from: 'ewr', to:'fco', seats: 1)
# AA.search(date: '2015-04-28', from: [ 'sfo' ], to:'cdg', seats: 1)

# United.search(date: '2015-04-28', from: [ 'sfo' ], to: ['iad','ewr','jfk'], seats: 1)






# def search_one
#   search_options = {
#     date: '2015-04-28',
#     from: 'SFO',
#     to: 'FRA'
#   }

#   United.search(search_options)
# end




# def search_all_routes(options)
#   if options[:date]
#     dates = [ Date.parse(options[:date]) ]
#   else
#     dates = [Date.parse('2015-06-20'), Date.parse('2015-06-21') ]
#   end

#   dates.each do |date|
#     STAR_ALLIANCE_TATL_ROUTE_PAIRS.each do |from_airport, to_airport|
#       rp = United::ResultsPage.new
#       rp.set_default_options
#       rp.set_options({
#         date: date,
#         from_airport: from_airport, 
#         to_airport: to_airport,
#         seats: 1
#       })

#       rp.load_results
#       rp.save_results
#     end
#   end
# end

# def search_many  
#   # from_airports = [ 'LAX', 'SFO', 'ORD', 'IAH' ]
#   # from_airports = [ 'SFO', 'LAX', 'ORD', 'EWR', 'IAH' ]
#   from_airports = [ 'KIX', 'NRT', 'HND' ]
#   to_airports = %w/SIN BKK/
#   from_date = Date.parse '2015-12-07'
#   to_date = Date.parse '2015-12-11'


#   from_airports.each do |from_airport|
#     to_airports.each do |to_airport|
#       (from_date..to_date).each do |date|
#         next if from_airport == to_airport

#         rp = United::ResultsPage.new
#         rp.set_default_options
#         rp.set_options({
#           date: date,
#           from_airport: from_airport, 
#           to_airport: to_airport
#         })

#         rp.load_results
#         rp.save_results
#       end
#     end
#   end

# end
