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
					puts key
					if(!sections[section.id][:data].has_key?(key))
						sections[section.id][:data][key] = [] 
					end
					sections[section.id][:data][key] <<  metadata
				end
			end
		end
		puts sections
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
