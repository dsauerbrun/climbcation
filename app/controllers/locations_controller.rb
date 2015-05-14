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
		puts sort_filter

		location_filter = Location.order(sort_filter).in_bounds([@swBounds, @neBounds]).joins(:climbing_types).where('climbing_types.name IN (?)',climbing_filter).where(continent: continent_filter).where('price_range_floor_cents < ?',price_filter).includes(:grade,:seasons).uniq 
		#location_filter = Location.all.joins(:climbing_types).includes(:grade,:seasons).uniq 
		location_filter.each do |location|
			location_json = location.get_location_json
			location_json['quotes'] = get_quotes('sfo','lax')
			location_list << location_json
		end
		render :json => location_list 
	end

	def get_quotes(origin_airport,destination_airport) 
		json_response = JSON.parse('{"Calendar":[{"CalendarId":1,"Date":"2015-05-13","Direct":true},{"CalendarId":2,"Date":"2015-05-14","Direct":true},{"CalendarId":3,"Date":"2015-05-15","Direct":true},{"CalendarId":4,"Date":"2015-05-16","Direct":true},{"CalendarId":5,"Date":"2015-05-17","Direct":true},{"CalendarId":6,"Date":"2015-05-18","Direct":true},{"CalendarId":7,"Date":"2015-05-19","Direct":true},{"CalendarId":8,"Date":"2015-05-20","Direct":true},{"CalendarId":9,"Date":"2015-05-21","Direct":true},{"CalendarId":10,"Date":"2015-05-22","Direct":true},{"CalendarId":11,"Date":"2015-05-23","Direct":true},{"CalendarId":12,"Date":"2015-05-24","Direct":true},{"CalendarId":13,"Date":"2015-05-25","Direct":true},{"CalendarId":14,"Date":"2015-05-26","Direct":true},{"CalendarId":15,"Date":"2015-05-27","Direct":true},{"CalendarId":16,"Date":"2015-05-28","Direct":true},{"CalendarId":17,"Date":"2015-05-29","Direct":true},{"CalendarId":18,"Date":"2015-05-30","Direct":true},{"CalendarId":19,"Date":"2015-05-31","Direct":true}],"Quotes":[{"CalendarId":1,"Price":222.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["vrda"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-13T00:00:00","Outbound_QuoteDateTime":"2015-05-13T21:06:00"},{"CalendarId":2,"Price":222.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["vrda"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-14T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:47:00"},{"CalendarId":3,"Price":216.2299,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-15T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:58:00"},{"CalendarId":4,"Price":205.4299,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-16T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:24:00"},{"CalendarId":5,"Price":211.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-17T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:25:00"},{"CalendarId":6,"Price":205.4299,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-18T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:50:00"},{"CalendarId":7,"Price":81.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-19T00:00:00","Outbound_QuoteDateTime":"2015-05-14T00:28:00"},{"CalendarId":8,"Price":168.1399,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-20T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:00:00"},{"CalendarId":9,"Price":170.1694,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-21T00:00:00","Outbound_QuoteDateTime":"2015-05-13T15:55:00"},{"CalendarId":10,"Price":168.1399,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-22T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:12:00"},{"CalendarId":11,"Price":140.6599,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-23T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:14:00"},{"CalendarId":12,"Price":140.6599,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-24T00:00:00","Outbound_QuoteDateTime":"2015-05-13T16:55:00"},{"CalendarId":13,"Price":79.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-25T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:23:00"},{"CalendarId":14,"Price":79.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-26T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:57:00"},{"CalendarId":15,"Price":74.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-27T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:05:00"},{"CalendarId":16,"Price":74.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-28T00:00:00","Outbound_QuoteDateTime":"2015-05-13T21:27:00"},{"CalendarId":17,"Price":75.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-29T00:00:00","Outbound_QuoteDateTime":"2015-05-13T16:47:00"},{"CalendarId":18,"Price":74.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-30T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:49:00"},{"CalendarId":19,"Price":76.0064,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-31T00:00:00","Outbound_QuoteDateTime":"2015-05-12T19:56:00"}],"Places":[{"PlaceId":"LAX","IataCityCode":"LAX","IataAirportCode":"LAX","Name":"Los Angeles International","RegionId":"CA","CityName":"Los Angeles","CountryName":"United States","Type":"Station","CityId":"LAXA"},{"PlaceId":"SFO","IataCityCode":"SFO","IataAirportCode":"SFO","Name":"San Francisco International","RegionId":"CA","CityName":"San Francisco","CountryName":"United States","Type":"Station","CityId":"SFOA"}],"Carriers":[{"CarrierId":"UA","Name":"United","IcaoCode":"UAL","IataCode":"UA"},{"CarrierId":"US","Name":"US Airways","IcaoCode":"USA","IataCode":"US"},{"CarrierId":"VX","Name":"Virgin America","IcaoCode":"VRD","IataCode":"VX"}],"Agents":[{"AgentId":"farm","Name":"BookAirFare"},{"AgentId":"uair","Name":"United"},{"AgentId":"vrda","Name":"Virgin America"}],"Metadata":{"MachineName":"FLPVWUK2IDS012","Revision":"1.0.4039.426","ExperimentAssignments":[{"Experiment":"INDS_b1b3","Variant":"Treatment"}],"Properties":[{"Name":"Browse Service Average Quote Age","Value":30733},{"Name":"Browse Service Node","Value":"FLPVWUK2IDS012"},{"Name":"Browse Service Version","Value":"1.0.4039.426"}]}}') 
		#dates[month][day]
		dates = {}
		json_response["Quotes"].each do |quote| 
			quote_date = Date.parse(quote['Outbound_DepartureDate'])
			if(!dates.has_key? quote_date.month)
				dates[quote_date.month] = {}
			end
			dates[quote_date.month][quote_date.day] = quote["Price"].to_i
		end
		return dates
	end

end

