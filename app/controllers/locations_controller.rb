class LocationsController < ApplicationController
	def show
		name_param= params[:slug]
		@location = Location.where(slug: name_param).first
		@close_locations = @location.get_locations_within_miles(200)
		@map_locations = {}
		@close_locations.each do |location|
			@map_locations[location.id] = {}
			@map_locations[location.id]['lat'] = location.latitude
			@map_locations[location.id]['lng'] = location.longitude
			@map_locations[location.id]['slug'] = location.slug
			@map_locations[location.id]['name'] = location.name
		end
		@map_locations = @map_locations.to_json
	end


	def filter_locations
		#Location.joins(:seasons).where('seasons.id IN (?)',[1,3])	
		#join filters = seasons,climbing_types
		#non-join filters = continent, price range
		#Location.where(continent: ['America', 'Europe'])
		if(params[:filters].has_key? :continent)
			continent_filter = params[:filters][:continent]
		else	
			continent_filter = Location.all.pluck(:continent).uniq 
		end
		if(params[:filters].has_key? :climbing_types)
			climbing_filter = params[:filters][:climbing_types]
		else	
			climbing_filter = ClimbingType.all.pluck(:id) 
		end
		if(params[:filters][:price] == ["all"])
			price_filter = 99999 
		else
			price_filter = params[:filters][:price].max
		end
		if(params.has_key? :sort)
			if(params[:sort]=="price")
				sort_filter = 'price_range_floor_cents ASC'
			elsif(params[:sort]=="grade")
				sort_filter = 'grade_id ASC'
			else
				sort_filter = 'name ASC'
			end
		end
		location_list = {}
		location_filter = Location.order(sort_filter).joins(:climbing_types).where('climbing_types.id IN (?)',climbing_filter).where(continent: continent_filter).where('price_range_floor_cents < ?',price_filter).includes(:grade,:seasons).uniq 
		location_filter.each do |location|
			puts location.climbing_types
			location_list[location.name] = {}
			location_list[location.name][:location] = location
			location_list[location.name][:seasons] = {}
			location_list[location.name][:home_thumb] = location.home_thumb.url
			location.seasons.each do |season|
				location_list[location.name][:seasons][season.id] = season.icon.url
			end
			location_list[location.name][:climbing_types] = {}
			location.climbing_types.each do |climbing_type|
				location_list[location.name][:climbing_types][climbing_type.id] = climbing_type.icon.url
			end
			location_list[location.name][:accommodations] = {}
			location.accommodations.each do |accommodation|
				location_list[location.name][:accommodations][accommodation.id] = accommodation.icon.url
			end
			location_list[location.name][:grade] = location.grade
		end
		render :json => location_list 
	end

	def angtest
		hello = {}
		hello['first'] = 'test'
		render :json => hello 

	end
end

