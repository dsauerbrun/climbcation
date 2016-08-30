require 'net/smtp'

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

	def location_names
		@locations = Location.all.pluck(:name,:slug)
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
		if(!params[:filter][:start_month].nil? and !params[:filter][:end_month].nil?)
			month_filter = []
			if params[:filter][:start_month] == params[:filter][:end_month]
				month_filter << params[:filter][:start_month].to_i
			elsif params[:filter][:start_month] > params[:filter][:end_month]
				(1..(params[:filter][:end_month].to_i)).each do |month_num|
					month_filter << month_num
				end
				((params[:filter][:start_month].to_i)..12).each do |month_num|
					month_filter << month_num
				end
			elsif params[:filter][:start_month] < params[:filter][:end_month]

				((params[:filter][:start_month].to_i)..(params[:filter][:end_month].to_i)).each do |month_num|
					month_filter << month_num
				end
			end
		end
		if(!params[:filter][:continents].nil?)
			continent_filter = params[:filter][:continents]
		else	
			continent_filter = Location.where(active: true).all.pluck(:continent).uniq 
		end
		if(!params[:filter][:accommodations].nil?)
			accommodation_filter = params[:filter][:accommodations]
		else
			accommodation_filter = nil
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
		
		location_filter = Location.select('locations.*, grades.order')
			.where(active: true).in_bounds([@swBounds, @neBounds])
			.joins(:grade)
			.joins(:seasons).where('seasons.numerical_value IN (?)', month_filter)
			.joins(:climbing_types).where('climbing_types.name IN (?)',climbing_filter)
			.joins('LEFT JOIN "info_sections" ON "info_sections"."location_id" = "locations"."id"')
			.where('lower("info_sections"."body") LIKE lower(?) OR lower("locations"."name") LIKE lower(?) OR lower("locations"."getting_in_notes") LIKE lower(?) OR lower("locations"."accommodation_notes") LIKE lower(?) OR lower("locations"."common_expenses_notes") LIKE lower(?) OR lower("locations"."saving_money_tips") LIKE lower(?)',string_filter,string_filter,string_filter,string_filter,string_filter,string_filter)
			.where(continent: continent_filter)
			.where('price_range_floor_cents < ?',price_filter)
			.uniq

			#handpicked sorting
			sort_filter = 'locations.name ASC'
			if(!params[:filter][:sort].nil?)
				if(params[:filter][:sort].include? 'price')
					sort_filter = 'price_range_floor_cents '
					if params[:filter][:sort][:price][:asc]
						sort_filter << 'ASC'
					else
						sort_filter << 'DESC'
					end
				elsif(params[:filter][:sort].include? 'grade')
					sort_filter = 'grades.order '
					if params[:filter][:sort][:grade][:asc]
						sort_filter << 'ASC'
					else
						sort_filter << 'DESC'
					end
				elsif params[:filter][:sort].include? 'distance'
					origin = Geokit::LatLng.new(params[:filter][:sort][:distance][:latitude], params[:filter][:sort][:distance][:longitude])
					location_filter = location_filter.by_distance(:origin => origin)
				else
					sort_filter = 'locations.name ASC'
				end
			end
			location_filter = location_filter.order(sort_filter, :id)
			#location_filter = location_filter.paginate(:page => page_num, :per_page => 8)

		if !accommodation_filter.nil?
			location_filter = location_filter.joins(:accommodation_location_details).where('accommodation_location_details.accommodation_id IN (?)',accommodation_filter)
		end

		locations_return = {}
		locations_return[:unpaginated] = []
		locations_return[:paginated] = []
		page_start = (page_num-1)*8
		page_end = ((page_num-1)*8) + 7
		location_page = location_filter[page_start..page_end]
		if !location_page.nil?
			location_page.each do |location|
				location_json = location.get_limited_location_json
				locations_return[:paginated] << location_json
			end
		end
		location_filter.each do |location|
			location_json = location
			locations_return[:unpaginated] << location_json
		end

		render :json => locations_return 
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
					sleep rand(5..10)/100
					queue_request(origin,location.airport_code,hydra,quotes,key_val,next_year,next_month,'')
					#end request multithreading
					hydra.run
				end
			end
		end
		render :json => quotes
	end

	def change_location_email
		@location = Location.find(params[:id])
		@location.submitter_email = params[:email]
		@location.save
		returnit = {'message' => 'success'}
		render :json => returnit
	end

	def new_location
		params[:location] = JSON.parse(params[:location]) if params[:location].is_a?(String)
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
		
		new_loc.change_getting_in(params[:location])
		new_loc.change_food_options(params[:location])
		new_loc.change_accommodations(params[:location])

		params[:location]['sections'].each do |section|
			InfoSection.create_new_info_section(new_loc.id, section)
		end
		new_loc.save
		returnit = {'id' => new_loc.id, 'slug' => new_loc.slug}
		render :json => returnit
	end

	def notify_admin(edit_type, location_id)
		message = 'Changing' << edit_type << ' for location id ' << location_id 
		smtp = Net::SMTP.new 'smtp.gmail.com', 587
		smtp.enable_starttls

		smtp.start('gmail.com', ENV['EMAIL_USER'], ENV['EMAIL_PASSWORD'], :login) do |smtp|
			smtp.send_message message, 'no-reply@climbcation.com', ENV['EMAIL_USER']
		end

	end

	def edit_sections
		new_id = ''
		if params[:section]['id'].nil?
			new_info = InfoSection.create_new_info_section(params[:locationId],params[:section])
			new_id = new_info.id
		else
			LocationEdit.create!(location_id: params[:locationId], edit_type: 'misc', edit: params[:section])
		end
		notify_admin('misc', params[:locationId])
		returnit = {'new_id' => new_id}
		render :json => returnit
	end

	def edit_food_options
		notify_admin('food options', params[:id])
		LocationEdit.create!(location_id: params[:id], edit_type: 'food_options', edit: params[:location])
		returnit = {'name' => 'hello'}
		render :json => returnit
	end


	def edit_accommodations
		notify_admin('accommodation', params[:id])
		LocationEdit.create!(location_id: params[:id], edit_type: 'accommodation', edit: params[:location])
		returnit = {'name' => 'hello'}
		render :json => returnit
	end


	def edit_getting_in
		notify_admin('getting in', params[:id])
		LocationEdit.create!(location_id: params[:id], edit_type: 'getting_in', edit: params[:location])
		returnit = {'name' => 'hello'}
		render :json => returnit
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
		user_agent_strings = []
		user_agent_strings << 'Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.93 Safari/537.36'
		user_agent_strings << 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.152 Safari/537.36'
		user_agent_strings << 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1'
		user_agent_strings << 'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko'
		user_agent_strings << 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A'

		options = {proxy: 'http://us-ca.proxymesh.com:31280', proxyuserpwd: ENV['PROXY_USER'] + ':' + ENV['PROXY_PASS'], :headers => { 'User-Agent' => user_agent_strings[rand(0..4)], 'X-ProxyMesh-Not_IP' => ip_blacklist, timeout: 4 }}
		return Typhoeus::Request.new("http://www.skyscanner.com/dataservices/browse/v3/mvweb/US/USD/en-US/calendar/#{origin_airport}/#{destination_airport}/#{year}-#{month}/?abvariant=EPS522_ReplaceMonthViewGlobalPartial:a|EPS522_ReplaceMonthViewGlobalPartial_V1:a", options)
	end

	def queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
		next_request = build_request(origin_airport,destination_airport,year,month,ip_blacklist)
		next_request.on_complete do |response|
			if response.success?
				if valid_json?(response.body)
					quotes[key_val][month] = process_quote_response(quotes[key_val],response,year,month)
				else
					if ip_blacklist == ''
						ip_blacklist = response.headers['X-ProxyMesh-IP']
					else
						ip_blacklist = ip_blacklist << ',' << response.headers['X-ProxyMesh-IP']	
					end
					queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
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
					ip_blacklist = ip_blacklist << ',' << response.headers['X-ProxyMesh-IP']	
				end
					puts response.headers['X-ProxyMesh-IP']
					puts 'ip blacklist here'
					puts ip_blacklist
				#queue_request(origin_airport,destination_airport,hydra,quotes,key_val,year,month,ip_blacklist)
			end
		end
		sleep rand(5..10)/100
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

