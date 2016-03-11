class LocationsController < ApplicationController
	def show
		name_param= params[:slug]
		return_map = {};
		
		@location = Location.where(slug: name_param).where(active: true).first
		return_map['nearby'] = @location.get_nearby_locations_json
		return_map['location'] = @location.get_location_json 
		return_map['sections'] = @location.get_sections
		render :json => return_map 
	end

	def location_names
		@locations = Location.all.pluck(:name)
		render :json => @locations
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
		if(!params[:page].nil?)
			page_num = params[:page]
		else
			page_num = 1
		end
		if(!params[:filter][:search].nil?)
			string_filter = params[:filter][:search]
			string_filter.insert(0,'%')
			string_filter.insert(-1,'%')
		else
			string_filter = '%%'
		end
		if(!params[:filter][:continents].nil?)
			continent_filter = params[:filter][:continents]
		else	
			continent_filter = Location.where(active: true).all.pluck(:continent).uniq 
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

		location_filter = Location.where(active: true).order(sort_filter).in_bounds([@swBounds, @neBounds]).joins(:climbing_types).where('climbing_types.name IN (?)',climbing_filter).joins('LEFT JOIN "info_sections" ON "info_sections"."location_id" = "locations"."id"').where('lower("info_sections"."body") LIKE lower(?) OR lower(array_dims(array["info_sections"."metadata"])) LIKE lower(?) OR lower("locations"."name") LIKE lower(?)',string_filter,string_filter,string_filter).where(continent: continent_filter).where('price_range_floor_cents < ?',price_filter).includes(:grade,:seasons).paginate(:page => page_num, :per_page => 5).uniq 
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
			origin = 'PHL'
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
			@locations = Location.where(active: true).where('slug IN (?)',slugs)
			@locations.each do |location| 
				key_val = "#{location.airport_code}-#{location.slug}-#{location.id}"
				if !location.airport_code.eql?(origin)
					quotes[key_val] = {}
					#request multithreads
					queue_request(origin,location.airport_code,hydra,quotes,key_val,curr_year,curr_month,'')
					#request for next month
					queue_request(origin,location.airport_code,hydra,quotes,key_val,next_year,next_month,'')
					#end request multithreading
					hydra.run
				end
			end
		end
		render :json => quotes
	end

	def new_location
		params[:location] = JSON.parse(params[:location])
		new_loc = Location.create!(name: params[:location]['name'], price_range_floor_cents: params[:location]['price_floor'].to_i, price_range_ceiling_cents: params[:location]['price_ceiling'].to_i,country: params[:location]['country'], airport_code: params[:location]['airport'], home_thumb: params[:file], slug: params[:location]['name'].parameterize )
		new_loc.grade = Grade.find(params[:location]['grade'])
		params[:location]['climbingTypes'].each do |id,selected|
			if selected == true
				new_loc.climbing_types << ClimbingType.find(id)
			end
		end
		params[:location]['months'].each do |id,selected|
			if selected == true
				new_loc.seasons << Season.find(id)
			end

		end
		
		change_getting_in(params[:location], new_loc.id)
		change_food_options(params[:location], new_loc.id)
		change_accommodations(params[:location], new_loc.id)

		params[:location]['sections'].each do |section|
			InfoSection.create_new_info_section(new_loc.id, section)
		end
		new_loc.save
		returnit = {'name' => 'hello'}
		render :json => returnit
	end

	def change_food_options(details, location_id)
		@location = Location.find(location_id)
		new_food_options = details[:foodOptionDetails]
		existing_food_options = []
		#remove null food_options
		new_food_options.delete_if { |k, v| v.nil? }
		#go through each existing food, remove if not in new and change if cost is different
		@location.food_option_location_details do |food_option|
			if new_food_options.key?(food_option.food_option.id)
				#food exists already
				if new_food_options[food_option.food_option.id].cost != food_option.cost
					food_option.cost = new_food_options[food_option.food_option.id].cost
					food_option.save
				end
			else
				#food option isnt in the new list so remove
				@location.food_option_location_details.delete(food_option)
			end
			existing_food_options << food_option.food_option.id
		end
		#add new food options if they dont exist already
		new_food_options.each do |key,new_food_option|
			if !existing_food_options.include? new_food_option[:id]
				new_food_option_obj = FoodOptionLocationDetail.create!(cost: new_food_option[:cost], food_option: FoodOption.find(new_food_option[:id]))
				@location.food_option_location_details << new_food_option_obj
			end
		end
		#change common expenses
		@location.common_expenses_notes = details[:commonExpensesNotes]
		#change saving money tips
		@location.saving_money_tips = details[:savingMoneyTips]
	
		@location.save
	end

	def change_accommodations(details, location_id)
		@location = Location.find(location_id)
		new_accommodations = details[:accommodations]
		existing_accommodations = []
		#remove null accommodations
		new_accommodations.delete_if { |k, v| v.nil? }
		#go through each existing accommodation, remove if not in new and change if cost is different
		@location.accommodation_location_details do |accommodation|
			if new_accommodations.key?(accommodation.accommodation.id)
				#accommodation exists already
				if new_accommodations[accommodation.accommodation.id].cost != accommodation.cost
					accommodation.cost = new_accommodations[accommodation.accommodation.id].cost
					accommodation.save
				end
			else
				#accommodation isnt in the new list so remove
				@location.accommodation_location_details.delete(accommodation)
			end
			existing_accommodations << accommodation.accommodation.id
		end
		#add new accommodations if they dont exist already
		new_accommodations.each do |key,new_accommodation|
			if !existing_accommodations.include? new_accommodation[:id]
				new_accommodation_obj = AccommodationLocationDetail.create!(cost: new_accommodation[:cost], accommodation: Accommodation.find(new_accommodation[:id]))
				@location.accommodation_location_details << new_accommodation_obj
			end
		end
		#change additional tips on staying
		@location.accommodation_notes = details[:accommodationNotes]
		#change closest accommodation to crags
		@location.closest_accommodation = details[:closestAccommodation]
	
		@location.save
	end

	def change_getting_in(details, location_id)
		@location = Location.find(location_id)
		transportations = details[:transportations]
		newTransportationIds = []
		existingTransportationIds = []
		#clean up transportations array(IE. convert to array of transportationIDs)
		transportations.each do |key, transportation|
			if transportation == true
				newTransportationIds << key	
			end
		end
		#cycle through transportations on location and remove the ones that arent in passed transportations
		@location.transportations.each do |transportation|
			if !newTransportationIds.include? transportation.id	
				@location.transportations.delete(transportation.id)
			else
				existingTransportationIds << transportation.id
			end
		end
		#cyclel through passed transportations and add the ones that arent in location
		newTransportationIds.each do |newTransportation|
			if !existingTransportationIds.include? newTransportation
				@location.transportations << Transportation.find(newTransportation)
			end
		end
		best_transportation = @location.primary_transportation
		#check if best option is different or non-existent
		if best_transportation.nil?
			new_best_transportation = PrimaryTransportation.create!(cost: details[:bestTransportationCost], transportation: Transportation.find(details[:bestTransportationId]))
			@location.primary_transportation = new_best_transportation
		else
			if best_transportation.transportation.id != details[:bestTransportationId]
				best_transportation.transportation.id = Transportation.find(details[:bestTransportationId])
			end
			#check if best option cost is different or non-existent
			if best_transportation.cost != details[:bestTransportationCost]
				best_transportation.cost = details[:bestTransportationCost]
			end
			best_transportation.save

		end	
		#replace additional tips
		@location.getting_in_notes = details[:gettingInNotes]
		#check if walking distance boolean is different
		if @location.walking_distance != details[:walkingDistance]
			@location.walking_distance = details[:walkingDistance]
		end

		@location.save
	end

	def process_quote_response(map_to_count, response, year, month)
		json_parse = JSON.parse(response.body)
		dates = {}
		counter = 0
		#count the number of dates we already have so we can start the counter properly
		map_to_count.each do |key,date_map|
			if map_to_count.has_key? key
				counter += map_to_count[key].length
			end
		end
		if json_parse.has_key? 'Quotes'
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
		end
		return dates
	end

	def build_request(origin_airport,destination_airport,year,month,ip_blacklist)
		user_agent_string = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.152 Safari/537.36'
		options = {proxy: 'http://us.proxymesh.com:31280', proxyuserpwd: ENV['PROXY_USER'] + ':' + ENV['PROXY_PASS'], :headers => { 'User-Agent' => user_agent_string, 'X-ProxyMesh-Not_IP' => ip_blacklist, timeout: 4 }}
		#Typhoeus::Config.verbose = true
		return Typhoeus::Request.new("http://www.skyscanner.com/dataservices/browse/v2/mvweb/US/USD/en-US/calendar/#{origin_airport}/#{destination_airport}/#{year}-#{month}/?includequotedate=true&includemetadata=true", options)
	end

	def queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
		next_request = build_request(origin_airport,destination_airport,year,month,ip_blacklist)
		next_request.on_complete do |response|
			if response.success?
				if valid_json?(response.body)
					puts 'success'
					quotes[key_val][month] = process_quote_response(quotes[key_val],response,year,month)
				else
					puts 'bad json'
					if ip_blacklist == ''
						ip_blacklist = response.headers['X-ProxyMesh-IP']
					else
						ip_blacklist = ip_blacklist<< ',' << response.headers['X-ProxyMesh-IP']	
					end
					queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
					puts response.headers['X-ProxyMesh-IP']
				end
			elsif response.timed_out?
				puts("got a timeout for #{location.airport_code} #{month} month")
				#queue_request(request,hydra,quotes,key_val,year,month)
				if ip_blacklist == ''
					ip_blacklist = response.headers['X-ProxyMesh-IP']
				else
					ip_blacklist = ip_blacklist<< ',' << response.headers['X-ProxyMesh-IP']	
				end
				queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
			elsif response.code == 0
				puts(response.return_message)
				#queue_request(request,hydra,quotes,key_val,year,month)
			else
				puts("HTTP request failed for #{origin_airport} #{month} month: " + response.code.to_s)
				puts response.body
				if ip_blacklist == ''
					ip_blacklist = response.headers['X-ProxyMesh-IP']
				else
					ip_blacklist = ip_blacklist<< ',' << response.headers['X-ProxyMesh-IP']	
				end
				queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
			end
		end
		hydra.queue(next_request)

	end

	class SkyscannerCache
		def get(request)
			Rails.cache.read(request)
		end

		def set(request,response)
			Rails.cache.write(request,response)
		end
	end

	def valid_json?(json)
		    JSON.parse(json)
				return true
	rescue
		    return false
	end
end

