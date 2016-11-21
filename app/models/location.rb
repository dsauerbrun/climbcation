class Location < ActiveRecord::Base
	has_paper_trail
	acts_as_mappable :lat_column_name => :latitude,:lng_column_name => :longitude
	belongs_to :grade

	validates_presence_of :slug
	has_and_belongs_to_many :grades
	has_and_belongs_to_many :transportations
	has_and_belongs_to_many :climbing_types
	has_and_belongs_to_many :seasons
	#FIX ME REMOVE accommodations
	has_and_belongs_to_many :accommodations
	has_many :info_sections
	has_many :accommodation_location_details
	has_many :food_option_location_details
	has_one :primary_transportation
	 
	has_attached_file :home_thumb, :default_url => "/images/:style/missing.png"
	validates_attachment_content_type :home_thumb, :content_type => /\Aimage\/.*\Z/
	def continent_enum
		['Asia','Australia','North America', 'South America','Africa','Europe','Antarctica']
	end
	def to_param
		slug	
	end

	def get_locations_within_miles(miles)
		begin
			locations = Location.all
			close_locations = []
			locations.each do |location|
				if self.distance_to(location) < miles and !self.eql?(location)
					close_locations << location
				end
			end
			return close_locations
		rescue
			return []
		end
	end

	def date_range
		months = self.seasons
		range_string = ''
		month_array = {}
		months.each do |month|
			month_array[month.numerical_value] = month.name
		end
		month_array = Hash[month_array.sort]
		
		previous_month = 0
		ranges = []
		counter = 0
		#this variable will be set to the month to stop at in case we have an edge case of december - january
		wrapper_break_month = -1
		if month_array.length == 12
			return 'Jan - Dec'
		end
		month_array.each do |numerical,month|
			counter += 1
			#first month of the range
			if previous_month == 0
				#corner case for if january and december are on
				if month_array.has_key? 12 and numerical == 1
					#get latest month
					latest_month = 13
					month_array.clone.to_a.reverse.each do |month_num, month_str|
						if latest_month - 1 == month_num
							latest_month = month_num
						end
					end
					ranges.push(month_array[latest_month])
					range_string << month_array[latest_month][0...3]
					wrapper_break_month = latest_month
				else
					ranges.push(month)
					range_string << month[0...3]
				end
			end
			if counter == month_array.length and previous_month != 0
				if !ranges.include?(month_array[previous_month])
					if wrapper_break_month == numerical
						ranges.push(month_array[previous_month])
						range_string << ' - ' << month_array[previous_month][0...3] 
					else
						ranges.push(month[previous_month])
						range_string << ' - ' << month[0...3]
					end
				else
					ranges.push(month)
					range_string << ', ' << month[0...3]
				end
			elsif (previous_month !=0 and previous_month+1 != numerical) 
				#if the previous month already exists in the array dont push it again(will happen if there is a one month window for a location)
				if !ranges.include?(month_array[previous_month])
					#corner case for if we had a wrapping date range(IE. December-january, we want to print the month without a comma then kill the loop
					if wrapper_break_month == numerical
						ranges.push(month_array[previous_month])
						range_string << ' - ' << month_array[previous_month][0...3]
						break
					else
						ranges.push(month_array[previous_month])
						range_string << ' - ' << month_array[previous_month][0...3] << ', '
					end
				else
					if wrapper_break_month == numerical
						if !ranges.include?(month_array[previous_month])
							ranges.push(month_array[previous_month])
							range_string << ' - ' << month_array[previous_month][0...3]
						end
						break
					else
						range_string << ', '
					end
				end
				ranges.push(month)
				range_string << month[0...3]
			end
			previous_month = numerical
		end
		return range_string
	end

	def get_best_transportation
		best_transport = {}
		if !self.primary_transportation.nil?
			best_transport['name'] = self.primary_transportation.transportation.name
			best_transport['cost'] = self.primary_transportation.cost
			best_transport['id'] = self.primary_transportation.transportation.id
		end
		return best_transport
	end

	def get_food_options
		food_options = []
		self.food_option_location_details.each do |food_option|
			foodObj = {}
			foodObj['name'] = food_option.food_option.name
			foodObj['cost'] = food_option.cost
			foodObj['id'] = food_option.food_option.id
			food_options.push(foodObj)
		end
		return food_options
	end

	def get_accommodations
		accommodations = []
		self.accommodation_location_details.each do |accommodation|
			accommObj = {}
			accommObj['url'] = accommodation.accommodation.icon.url
			accommObj['name'] = accommodation.accommodation.name
			accommObj['cost'] = accommodation.cost
			accommObj['id'] = accommodation.accommodation.id
			accommodations.push(accommObj)
		end
		return accommodations
	end

	def get_transportations
		transportations = []
		self.transportations.each do |transportation|
			transportationObj = {}
			transportationObj['id'] = transportation.id
			transportationObj['name'] = transportation.name
			transportations.push(transportationObj)
		end
		return transportations
	end

	def get_climbing_types
		climbing_types = {}
		self.climbing_types.each do |climbing_type|
			climbing_types[climbing_type.id] = {}
			climbing_types[climbing_type.id]['url'] = climbing_type.icon.url
			climbing_types[climbing_type.id]['name'] = climbing_type.name
		end
		return climbing_types
	end

	def get_seasons
		seasons = {}
		self.seasons.each do |season|
			seasons[season.id] = {}
			seasons[season.id]['url'] = season.icon.url
			seasons[season.id]['name'] = season.name
		end
		return seasons
	end

	def get_sections
		sections = {}
		self.info_sections.each do |section|
			sections[section.id] = {}
			sections[section.id][:id] = section.id
			sections[section.id][:title] = section.title
			sections[section.id][:body] = section.body
			sections[section.id][:subsections] = {} 
			if section.metadata.present?
				section.metadata.each do |key,metadata|
					if(!sections[section.id][:subsections].has_key?(key))
						sections[section.id][:subsections][key] = {} 
					end
					sections[section.id][:subsections][key] =  {title: key, subsectionDescriptions:metadata}
				end
			end
		end
		return sections

	end

	def get_limited_location_json
		json_return = {}
		json_return[:location] = self
		json_return[:latitude] = self.latitude
		json_return[:longitude] = self.longitude
		json_return[:slug] = self.slug
		json_return[:name] = self.name
		json_return[:country] = self.country
		json_return[:price_range_floor_cents] = self.price_range_floor_cents
		json_return[:price_range_ceiling_cents] = self.price_range_ceiling_cents
		json_return[:home_thumb] = self.home_thumb.url
		json_return[:climbing_types] = self.get_climbing_types
		json_return[:grades] = self.grades.collect { |grade| grade.html_attributes }
		json_return[:airport_code] = self.airport_code
		json_return[:date_range] = self.date_range
		json_return[:id] = self.id
		
		#new stuff
		json_return[:accommodations] = self.get_accommodations

		return json_return
	end

	def get_location_json
		json_return = {}
		json_return[:location] = self
		json_return[:latitude] = self.latitude
		json_return[:longitude] = self.longitude
		json_return[:slug] = self.slug
		json_return[:name] = self.name
		json_return[:country] = self.country
		json_return[:price_range_floor_cents] = self.price_range_floor_cents
		json_return[:price_range_ceiling_cents] = self.price_range_ceiling_cents
		json_return[:home_thumb] = self.home_thumb.url
		json_return[:seasons] = self.get_seasons
		json_return[:climbing_types] = self.get_climbing_types
		json_return[:grades] = self.grades.collect {|grade| grade.html_attributes }
		json_return[:airport_code] = self.airport_code
		json_return[:date_range] = self.date_range
		json_return[:submitter_email] = self.submitter_email
		json_return[:id] = self.id
		
		#new stuff
		json_return[:closest_accommodation] = self.closest_accommodation
		json_return[:walking_distance] = self.walking_distance
		json_return[:getting_in_notes] = self.getting_in_notes
		json_return[:accommodation_notes] = self.accommodation_notes
		json_return[:common_expenses_notes] = self.common_expenses_notes
		json_return[:saving_money_tip] = self.saving_money_tips
		
		json_return[:accommodations] = self.get_accommodations
		json_return[:transportations] = self.get_transportations
		json_return[:best_transportation] = self.get_best_transportation
		json_return[:food_options] = self.get_food_options

		return json_return
	end
	
	def get_nearby_locations_json
		close_locations = self.get_locations_within_miles(300)
		map_locations = []
		close_locations.each do |location|
			tmp_location = {}
			tmp_location['lat'] = location.latitude
			tmp_location['lng'] = location.longitude
			tmp_location['slug'] = location.slug
			tmp_location['name'] = location.name
			tmp_location['country'] = location.country
			tmp_location['distance'] = self.distance_to(location).to_i
			tmp_location['climbing_types'] = location.get_climbing_types
			map_locations << tmp_location
		end
		map_locations.sort_by! { |location| location['distance'] }
		return map_locations
	end

	def change_accommodations(details)
		new_accommodations = details['accommodations']
		existing_accommodations = []
		#remove null accommodations
		new_accommodations.delete_if { |k, v| v.nil? }
		#go through each existing accommodation, remove if not in new and change if cost is different
		self.accommodation_location_details.each do |accommodation|
			if new_accommodations.key?(accommodation.accommodation.id.to_s)
				#accommodation exists already
				if new_accommodations[accommodation.accommodation.id.to_s]['cost'] != accommodation.cost
					accommodation.cost = new_accommodations[accommodation.accommodation.id.to_s]['cost']
					accommodation.save
				end
			else
				#accommodation isnt in the new list so remove
				self.accommodation_location_details.delete(accommodation)
			end
			existing_accommodations << accommodation.accommodation.id
		end
		#add new accommodations if they dont exist already
		new_accommodations.each do |key,new_accommodation|
			if !existing_accommodations.include? new_accommodation['id']
				new_accommodation_obj = AccommodationLocationDetail.create!(cost: new_accommodation['cost'], accommodation: Accommodation.find(new_accommodation['id']))
				self.accommodation_location_details << new_accommodation_obj
			end
		end
		#change additional tips on staying
		self.accommodation_notes = details['accommodationNotes']
		#change closest accommodation to crags
		self.closest_accommodation = details['closestAccommodation']
	
		self.save
	end

	def change_food_options(details)
		new_food_options = details['foodOptionDetails']
		existing_food_options = []
		#remove null food_options
		new_food_options.delete_if { |k, v| v.nil? }
		#go through each existing food, remove if not in new and change if cost is different
		self.food_option_location_details.each do |food_option|
			if new_food_options.key?(food_option.food_option.id.to_s)
				#food exists already
				if new_food_options[food_option.food_option.id.to_s]['cost'] != food_option.cost
					food_option.cost = new_food_options[food_option.food_option.id.to_s]['cost']
					food_option.save
				end
			else
				#food option isnt in the new list so remove
				self.food_option_location_details.delete(food_option)
			end
			existing_food_options << food_option.food_option.id
		end
		#add new food options if they dont exist already
		new_food_options.each do |key,new_food_option|
			if !existing_food_options.include? new_food_option['id'].to_i
				new_food_option_obj = FoodOptionLocationDetail.create!(cost: new_food_option['cost'], food_option: FoodOption.find(new_food_option['id'].to_i))
				self.food_option_location_details << new_food_option_obj
			end
		end
		#change common expenses
		self.common_expenses_notes = details['commonExpensesNotes']
		#change saving money tips
		self.saving_money_tips = details['savingMoneyTips']
	
		self.save
	end

	def change_getting_in(details)
		transportations = details['transportations']
		newTransportationIds = []
		existingTransportationIds = []
		if !transportations.nil?
			#clean up transportations array(IE. convert to array of transportationIDs)
			transportations.each do |key, transportation|
				if transportation == true
					newTransportationIds << key	
				end
			end
			#cycle through transportations on location and remove the ones that arent in passed transportations
			self.transportations.each do |transportation|
				if !newTransportationIds.include? transportation.id	
					self.transportations.delete(transportation.id)
				else
					existingTransportationIds << transportation.id
				end
			end
			#cyclel through passed transportations and add the ones that arent in location
			newTransportationIds.each do |newTransportation|
				if !existingTransportationIds.include? newTransportation
					self.transportations << Transportation.find(newTransportation)
				end
			end
		end
		best_transportation = self.primary_transportation
		if !details['bestTransportationCost'].nil? or !details['bestTransportationId'].nil?
			#check if best option is different or non-existent
			if best_transportation.nil? and !details['bestTransportationId'].nil?
				details['bestTransportationCost'] ||= -1
				new_best_transportation = PrimaryTransportation.create!(cost: details['bestTransportationCost'], transportation: Transportation.find(details['bestTransportationId']))
				self.primary_transportation = new_best_transportation
			else
				if !details['bestTransportationId'].nil? and best_transportation.transportation.id != details['bestTransportationId'].to_i
					best_transportation.transportation = Transportation.find(details['bestTransportationId'])
				end
				#check if best option cost is different or non-existent
				if !details['bestTransportationCost'].nil? or best_transportation.cost != details['bestTransportationCost']
					best_transportation.cost = details['bestTransportationCost']
				end
				best_transportation.save
			end	
		end
		#replace additional tips
		self.getting_in_notes = details['gettingInNotes']
		#check if walking distance boolean is different
		if self.walking_distance != details['walkingDistance']
			self.walking_distance = details['walkingDistance']
		end

		self.save
	end

	def change_sections(details)
		section = InfoSection.find(details['id'])
		section.title = details['title']
		section.body = details['body']
		section.save
	end

end
