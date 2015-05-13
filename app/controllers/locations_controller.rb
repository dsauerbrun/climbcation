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
		location_list = {}
		puts params[:filter][:continents]
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
=begin
		if(params.has_key? :sort)
			if(params[:sort]=="price")
				sort_filter = 'price_range_floor_cents ASC'
			elsif(params[:sort]=="grade")
				sort_filter = 'grade_id ASC'
			else
				sort_filter = 'name ASC'
			end
		end
=end
				sort_filter = 'name ASC'

		location_filter = Location.order(sort_filter).joins(:climbing_types).where('climbing_types.name IN (?)',climbing_filter).where(continent: continent_filter).where('price_range_floor_cents < ?',price_filter).includes(:grade,:seasons).uniq 
		#location_filter = Location.all.joins(:climbing_types).includes(:grade,:seasons).uniq 
		location_filter.each do |location|
			location_list[location.name] = location.get_location_json
		end
		render :json => location_list 
	end

	def angtest
		hello = {}
		hello['first'] = 'test'
		render :json => hello 

	end

end

