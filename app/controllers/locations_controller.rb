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
		if(!params[:mapFilter][:southwest][:longitude].nil? && params[:mapFilter][:southwest][:longitude] != -180)
			@swBounds = Geokit::LatLng.new(params[:mapFilter][:southwest]['latitude'],params[:mapFilter][:southwest]['longitude'])
			@neBounds = Geokit::LatLng.new(params[:mapFilter][:northeast]['latitude'],params[:mapFilter][:northeast]['longitude'])
		else
			@swBounds = Geokit::LatLng.new(-90,-180)
			@neBounds = Geokit::LatLng.new(90,180)
		end
		location_filter = Location.select('locations.*')
                  .where(active: true).in_bounds([@swBounds, @neBounds])

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
                  location_filter = location_filter.joins('LEFT JOIN "info_sections" ON "info_sections"."location_id" = "locations"."id"')
                  .where('lower("info_sections"."body") LIKE lower(?) OR lower("locations"."name") LIKE lower(?) OR lower("locations"."country") LIKE lower(?) OR lower("locations"."continent") LIKE lower(?) OR lower("locations"."getting_in_notes") LIKE lower(?) OR lower("locations"."accommodation_notes") LIKE lower(?) OR lower("locations"."common_expenses_notes") LIKE lower(?) OR lower("locations"."saving_money_tips") LIKE lower(?)',string_filter,string_filter,string_filter,string_filter,string_filter,string_filter, string_filter, string_filter)
		end

                if(!params[:filter][:start_month].nil? && !params[:filter][:end_month].nil? && !(params[:filter][:start_month] == 1 && params[:filter][:end_month] == 12))
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

                  location_filter = location_filter.joins(:seasons).where('seasons.numerical_value IN (?)', month_filter)
		end

                if(!params[:filter][:climbing_types].nil? and params[:filter][:climbing_types].any?)
                  climbing_filter = params[:filter][:climbing_types]
                  location_filter = location_filter.joins(:climbing_types).where('climbing_types.name IN (?)',climbing_filter)
                end

                if (params[:filter][:rating] and params[:filter][:rating].any?)
                  rating_filter = params[:filter][:rating]
                  location_filter = location_filter.where('rating in (?)', rating_filter)
                end

                if (params[:filter][:solo_friendly])
                  solo_friendly_filter = params[:filter][:solo_friendly]
                  location_filter = location_filter.where('solo_friendly is ?', solo_friendly_filter)
                end

                if(params[:filter][:no_car])
                  no_car_filter = params[:filter][:no_car]
                  location_filter = location_filter.where('(closest_accommodation = \'<1 mile\' OR closest_accommodation = \'1-2 miles\')').where('walking_distance is true')
                end

                if params[:filter][:grades].keys.length > 0
                  grade_filter = []
                  climbing_type_grade_filter = []
                  params[:filter][:grades].each do |typeId, grades|
                    climbing_type_grade_filter << typeId
                    grades.each {|grade| grade_filter << grade}
                  end

                  location_filter = location_filter.joins(:grades).where('grades.id IN (?) OR NOT EXISTS (SELECT 1 FROM grades_locations as t1 inner join grades as t2 on t2.id = t1.grade_id WHERE locations.id = t1.location_id and t2.climbing_type_id in (?))',grade_filter, climbing_type_grade_filter)
                end 


                #handpicked sorting
                sort_filter = 'locations.name ASC'
                if(!params[:filter][:sort].nil?)
                        if params[:filter][:sort].include? 'distance'
                                origin = Geokit::LatLng.new(params[:filter][:sort][:distance][:latitude], params[:filter][:sort][:distance][:longitude])
                                location_filter = location_filter.by_distance(:origin => origin)
                        elsif params[:filter][:sort].include? 'rating'
                                sort_filter = 'rating '
                                if params[:filter][:sort][:rating][:asc]
                                        sort_filter << 'ASC'
                                else
                                        sort_filter << 'DESC'
                                end
                        else
                                sort_filter = 'locations.name ASC'
                        end
                end
                location_filter = location_filter.order(sort_filter, :id)

                location_filter = location_filter.group('locations.id')
                if page_num > 1
                  location_filter = location_filter.paginate(:page => page_num, :per_page => 8)
                end

                location_filter = location_filter.uniq

                locations_return = {}
                locations_return[:unpaginated] = []
                locations_return[:paginated] = []
                page_start = (page_num-1)*8
                page_end = ((page_num-1)*8) + 7
                if page_num == 1
                  location_page = location_filter[page_start..page_end]
                else
                  location_page = location_filter
                end

		if !location_page.nil?
                  location_page.each do |location|
                    location_json = location.get_limited_location_json
                    locations_return[:paginated] << location_json
                  end
		end

                if page_num == 1
                  all_location_ids = location_filter.map{|loc| loc.id}
                  location_climbing_types = ClimbingType.select('climbing_types.*, climbing_types_locations.location_id as location_id').joins('LEFT JOIN climbing_types_locations on climbing_types_locations.climbing_type_id = climbing_types.id').where('climbing_types_locations.location_id in (?)', all_location_ids)
                  location_seasons = Season.select('seasons.id, seasons.name, seasons.numerical_value, locations_seasons.location_id as location_id').joins('LEFT JOIN locations_seasons on locations_seasons.season_id = seasons.id').where('locations_seasons.location_id in (?)', all_location_ids)

                  location_filter.each do |location|
                    location_json = location.get_limited_unpaginated_location_json
                    filtered_seasons = location_seasons.select {|season| season.location_id == location.id}
                    filtered_climbing_types = location_climbing_types.select {|type| type.location_id == location.id}
                    location_json[:date_range] = location.date_range(filtered_seasons)
                    location_json[:climbing_types] = filtered_climbing_types.map {|type| type.html_attributes}
                    locations_return[:unpaginated] << location_json
                  end
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
					quotes[key_val]['slug'] = location.slug
					quotes[key_val]['origin_airport'] = origin
					quotes[key_val]['airport_code'] = location.airport_code
					quotes[key_val]['id'] = location.id

					quotes[key_val]['quotes'] = {}
					#request multithreads
					queue_request(origin,location.airport_code,hydra,quotes[key_val]['quotes'],curr_year,curr_month)
					#request for next month
					queue_request(origin,location.airport_code,hydra,quotes[key_val]['quotes'],next_year,next_month)
					#end request multithreading
					quotes[key_val]['referral'] = "http://partners.api.skyscanner.net/apiservices/referral/v1.0/US/USD/EN-US/#{origin}/#{location.airport_code}/#{curr_year}-#{curr_month}?apiKey=#{ENV['SKYSCANNER_API']}"
				end
			end
			hydra.run
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
		new_loc = Location.create!(name: params[:location]['name'], rating: params[:location]['rating'], solo_friendly: params[:location]['solo_friendly'], price_range_floor_cents: params[:location]['price_floor'].to_i, price_range_ceiling_cents: params[:location]['price_ceiling'].to_i,country: params[:location]['country'], airport_code: params[:location]['airport'], home_thumb: params[:file], slug: params[:location]['name'].parameterize, user_id: session[:user_id], submitter_email: session[:email] )
		params[:location]['grade'].each do |gradeId|
			new_loc.grades << Grade.find(gradeId)
		end
		params[:location]['climbingTypes'].each do |id, selected|
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
    notify_admin('new', new_loc.id)
		returnit = {'id' => new_loc.id, 'slug' => new_loc.slug}
		render :json => returnit
	end

	def notify_admin(edit_type, location_id)
		begin
      editLocation = Location.find(location_id)
      if (edit_type == 'new')
        message = 'new location created ' << location_id << ' ' <<  editLocation.name
      else
        message = 'Changing' << edit_type << ' for location id ' << location_id << ' ' <<  editLocation.name
      end
			smtp = Net::SMTP.new 'smtp.gmail.com', 587
			smtp.enable_starttls

			smtp.start('gmail.com', ENV['EMAIL_USER'], ENV['EMAIL_PASSWORD'], :plain) do |smtp|
				smtp.send_message message, 'no-reply@climbcation.com', ENV['EMAIL_USER']
			end
		rescue => exception
			print exception.backtrace
		end
	end

	def edit_sections
		new_id = ''
		if params[:section]['id'].nil?
			new_info = InfoSection.create_new_info_section(params[:locationId],params[:section])
			new_id = new_info.id
		else
			LocationEdit.create!(location_id: params[:locationId], edit_type: 'misc', edit: params[:section], user_id: session[:user_id])
		end
		notify_admin('misc', params[:locationId])
		returnit = {'new_id' => new_id}
		render :json => returnit
	end

	def edit_food_options
          locationObj = params[:location]
          editObject = {
            foodOptionDetails: locationObj[:foodOptionDetails],
            commonExpensesNotes: locationObj[:commonExpensesNotes],
            savingMoneyTips: locationObj[:savingMoneyTips]
          }
          LocationEdit.create!(location_id: params[:id], edit_type: 'food_options', edit: editObject, user_id: session[:user_id])
          notify_admin('food options', params[:id])
          returnit = {'name' => 'hello'}
          render :json => returnit
	end


	def edit_accommodations
          locationObj = params[:location]
          editObject = {
            accommodations: locationObj[:accommodations],
            accommodationNotes: locationObj[:accommodationNotes],
            closestAccommodation: locationObj[:closestAccommodation]
          }
          LocationEdit.create!(location_id: params[:id], edit_type: 'accommodation', edit: editObject, user_id: session[:user_id])
          notify_admin('accommodation', params[:id])
          returnit = {'name' => 'hello'}
          render :json => returnit
	end


	def edit_getting_in
          locationObj = params[:location]
          editObject = {
            transportations: locationObj[:transportations],
            bestTransportationCost: locationObj[:bestTransportationCost],
            bestTransportationId: locationObj[:bestTransportationId],
            gettingInNotes: locationObj[:gettingInNotes],
            walkingDistance: locationObj[:walkingDistance]
          }
          LocationEdit.create!(location_id: params[:id], edit_type: 'getting_in', edit: editObject, user_id: session[:user_id])
          notify_admin('getting in', params[:id])
          returnit = {'name' => 'hello'}
          render :json => returnit
	end


	def process_quote_response(map_to_count, response, year, month)
		json_parse = JSON.parse(response.body) if response.body.is_a?(String)
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
				quote_date = Date.parse(quote['OutboundLeg']['DepartureDate'])
				if(counter > 30)
					break
				end
				#since we are caching requests we need to check to see if the date we are tracking is old
				if(quote_date >= Date.today)
					#if price already exists or new price is lower than existing price
					if(!dates.has_key? quote_date.day or (dates.has_key? quote_date.day and dates[quote_date.day] > quote["MinPrice"].to_i))
						dates[quote_date.day] = quote["MinPrice"].to_i
						counter += 1
					end
				end
			end
		end
		return dates
	end

	def build_request(origin_airport,destination_airport,year,month)
		options = {:headers => { 'Accept' => 'application/json', 'X-RapidAPI-Key' => ENV['SKYSCANNER_API'], 'X-RapidAPI-Host' => 'skyscanner-skyscanner-flight-search-v1.p.rapidapi.com'}}
    
		return Typhoeus::Request.new("https://skyscanner-skyscanner-flight-search-v1.p.rapidapi.com/apiservices/browsequotes/v1.0/US/USD/en-US/#{origin_airport}/#{destination_airport}/#{year}-#{month}", options)
	end

	def queue_request(origin_airport,destination_airport,hydra,quotes,year,month)
		next_request = build_request(origin_airport,destination_airport,year,month)
		next_request.on_complete do |response|
			if response.success?
				if valid_json?(response.body)
					quotes[month] = process_quote_response(quotes,response,year,month)
				else
					queue_request(origin_airport,destination_airport,hydra,quotes,year,month)
				end
			elsif response.timed_out?
				queue_request(origin_airport,destination_airport,hydra,quotes,year,month)
			elsif response.code == 0
			else
				puts("HTTP request failed for #{origin_airport} #{month} month: " + response.code.to_s)
				puts response.body
			end
		end
		hydra.queue(next_request)
	end

	class SkyscannerCache
		def get(request)
			Rails.cache.read(request)
		end

		def set(request,response)
			Rails.cache.write(request,response, expires_in: 24.hours)
		end
	end

	def valid_json?(json)
		    JSON.parse(json)
				return true
	rescue
		    return false
	end
end

