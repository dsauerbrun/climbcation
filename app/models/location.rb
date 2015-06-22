class Location < ActiveRecord::Base
	acts_as_mappable :lat_column_name => :latitude,:lng_column_name => :longitude


	validates_presence_of :slug
	belongs_to :grade
	has_and_belongs_to_many :climbing_types
	has_and_belongs_to_many :seasons
	has_and_belongs_to_many :accommodations
	has_many :info_sections
	 
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
					puts month_array.clone.to_a.reverse
					month_array.clone.to_a.reverse.each do |month_num, month_str|
						puts 'loop month array1'
						puts month_num.to_s << ',' << month_str
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
				ranges.push(month)
				range_string << ' - ' <<month[0...3]
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

	def get_accommodations
		accommodations = {}
		self.accommodations.each do |accommodation|
			accommodations[accommodation.id] = {}
			accommodations[accommodation.id]['url'] = accommodation.icon.url
			accommodations[accommodation.id]['name'] = accommodation.name
		end
		return accommodations
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
			sections[section.id][:title] = section.title
			sections[section.id][:body] = section.body
			sections[section.id][:data] = {} 
			if section.metadata.present?
				section.metadata.each do |key,metadata|
					if(!sections[section.id][:data].has_key?(key))
						sections[section.id][:data][key] = [] 
					end
					sections[section.id][:data][key] <<  metadata
				end
			end
		end
		return sections

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
		json_return[:accommodations] = self.get_accommodations 
		json_return[:grade] = self.grade.us 
		json_return[:airport_code] = self.airport_code
		json_return[:date_range] = self.date_range
		return json_return
	end
	
	def get_nearby_locations_json
		@close_locations = self.get_locations_within_miles(200)
		@map_locations = {}
		@close_locations.each do |location|
			@map_locations[location.id] = {}
			@map_locations[location.id]['lat'] = location.latitude
			@map_locations[location.id]['lng'] = location.longitude
			@map_locations[location.id]['slug'] = location.slug
			@map_locations[location.id]['name'] = location.name
			@map_locations[location.id]['country'] = location.country
			@map_locations[location.id]['distance'] = self.distance_to(location).to_i

		end
		return @map_locations
	end

end
