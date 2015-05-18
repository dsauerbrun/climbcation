class LocationsController < ApplicationController
	def show
		name_param= params[:slug]
		return_map = {};
		
		@location = Location.where(slug: name_param).first
		return_map['nearby'] = @location.get_nearby_locations_json
		return_map['location'] = @location.get_location_json 
		return_map['sections'] = @location.get_sections
		render :json => return_map 
	end

	def filter_locations
		location_list = [] 
		#mappicked filters
		#check to see if map moved
		if(!params[:mapFilter][:southwest]['longitude'].nil?)
			@swBounds = Geokit::LatLng.new(params[:mapFilter][:southwest]['latitude'],params[:mapFilter][:southwest]['longitude'])
			@neBounds = Geokit::LatLng.new(params[:mapFilter][:northeast]['latitude'],params[:mapFilter][:northeast]['longitude'])
		else
			@swBounds = Geokit::LatLng.new(-90,-180)
			@neBounds = Geokit::LatLng.new(90,180)
		end
		#handpicked filters
		if(!params[:filter][:continents].nil?)
			continent_filter = params[:filter][:continents]
		else	
			continent_filter = Location.all.pluck(:continent).uniq 
		end
		if(!params[:filter][:climbing_types].nil?)
			climbing_filter = params[:filter][:climbing_types]
		else	
			climbing_filter = ClimbingType.all.pluck(:name) 
		end
		if(!params[:filter][:price_max].nil?)
			price_filter = params[:filter][:price_max].max
		else
			price_filter = 99999 
		end
		#handpicked sorting
		sort_filter = 'name ASC'
		if(!params[:filter][:sort].nil?)
			if(params[:filter][:sort].include? 'price')
				sort_filter = 'price_range_floor_cents ASC'
			elsif(params[:filter][:sort].include? 'grade')
				sort_filter = 'grade_id ASC'
			else
				sort_filter = 'name ASC'
			end
		end

		location_filter = Location.order(sort_filter).in_bounds([@swBounds, @neBounds]).joins(:climbing_types).where('climbing_types.name IN (?)',climbing_filter).where(continent: continent_filter).where('price_range_floor_cents < ?',price_filter).includes(:grade,:seasons).uniq 
		#location_filter = Location.all.joins(:climbing_types).includes(:grade,:seasons).uniq 
		location_filter.each do |location|
			location_json = location.get_location_json
			location_list << location_json
		end
		render :json => location_list 
	end

	def collect_locations_quotes
		quotes = {}
		if ( params.has_key? :origin_airport)
			origin = params[:origin_airport]
		else
			origin = 'SFO'
		end
		if (params.has_key? :slugs)
			curr_month = Date.today.strftime("%m")
			next_month = (Date.today+1.month).strftime("%m")
			curr_year = Date.today.strftime("%Y")
			if next_month.eql?('01')
				next_year = (Date.today+1.year).strftime("%Y")
			else
				next_year = Date.today.strftime("%Y")
			end
			slugs = params[:slugs]
			request_list = {}
			Typhoeus::Config.cache = SkyscannerCache.new
			hydra = Typhoeus::Hydra.hydra
			@locations = Location.where('slug IN (?)',slugs)
			@locations.each do |location| 
				key_val = "#{location.airport_code}-#{location.slug}"
				if !location.airport_code.eql?(origin)
					quotes[key_val] = {}
					#request multithreads
					curr_request = build_request(origin,location.airport_code,curr_year,curr_month)
					curr_request.on_complete do |response|
						quotes[key_val][curr_month] = process_quote_response(quotes[key_val],response,curr_year,curr_month)
					end
					hydra.queue(curr_request)
					next_request = build_request(origin,location.airport_code,next_year,next_month)
					next_request.on_complete do |response|
						quotes[key_val][next_month] = process_quote_response(quotes[key_val],response,curr_year,curr_month)
					end
					hydra.queue(next_request)
					#end request multithreading
					hydra.run
				end
			end
		end
		render :json => quotes
	end

	def process_quote_response(map_to_count, response, year, month)
		puts response.body
		puts 'here is resp'
		puts response
		json_parse = JSON.parse(response.body)
		dates = {}
		counter = 0
		#count the number of dates we already have so we can start the counter properly
		map_to_count.each do |key,date_map|
			if map_to_count.has_key? key
				counter += map_to_count[key].length
			end
		end
		json_parse["Quotes"].each do |quote| 
			quote_date = Date.parse(quote['Outbound_DepartureDate'])
			if(counter > 30)
				break
			end
			#since we are caching requests we need to check to see if the date we are tracking is old
			if(quote_date >= Date.today)
				#if price already exists or new price is lower than existing price
				if(!dates.has_key? quote_date.day or (dates.has_key? quote_date.day and dates[quote_date.day] > quote["Price"].to_i))
					dates[quote_date.day] = quote["Price"].to_i
					counter += 1
				end
			end
		end
		return dates
	end

	def build_request(origin_airport,destination_airport,year,month)
		return Typhoeus::Request.new("http://www.skyscanner.com/dataservices/browse/v2/mvweb/US/USD/en-US/calendar/#{origin_airport}/#{destination_airport}/#{year}-#{month}/?includequotedate=true&includemetadata=true")
	end

	class SkyscannerCache
		def get(request)
			Rails.cache.read(request)
		end

		def set(request,response)
			Rails.cache.write(request,response)
		end
	end
end

