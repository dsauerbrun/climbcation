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
			location_list << location_json
		end
		render :json => location_list 
	end

	def collect_locations_quotes
		quotes = {}
		if (params.has_key? :slugs)
			slugs = params[:slugs]
			@locations = Location.where('slug IN (?)',slugs)
			@locations.each do |location| 
				if !location.airport_code.eql?('LAX')
					quotes[location.slug] = get_route_quotes('LAX',location.airport_code)
				end
			end
		end
		render :json => quotes
	end

	class SkyscannerCache
		def get(request)
			Rails.cache.read(request)
		end

		def set(request,response)
			Rails.cache.write(request,response)
		end
	end
	def get_route_quotes(origin_airport,destination_airport) 
		Typhoeus::Config.cache = SkyscannerCache.new
		#dates[month][day]
		json_responseFirstMonth = getmockdata(1)
		json_responseSecondMonth = getmockdata(2)
		hydra = Typhoeus::Hydra.hydra
		curr_month = Date.today.strftime("%m")
		next_month = (Date.today+1.month).strftime("%m")
		curr_year = Date.today.strftime("%Y")
		if next_month.eql?('01')
			next_year = (Date.today+1.year).strftime("%Y")
		else
			next_year = Date.today.strftime("%Y")
		end
		first_month_url = "http://www.skyscanner.com/dataservices/browse/v2/mvweb/US/USD/en-US/calendar/#{origin_airport}/#{destination_airport}/#{curr_year}-#{curr_month}/?includequotedate=true&includemetadata=true"
		second_month_url = "http://www.skyscanner.com/dataservices/browse/v2/mvweb/US/USD/en-US/calendar/#{origin_airport}/#{destination_airport}/#{next_year}-#{next_month}/?includequotedate=true&includemetadata=true"
		first_month_request = Typhoeus::Request.new(first_month_url)
		second_month_request = Typhoeus::Request.new(second_month_url)
		first_month_request.on_complete do |response|
			json_responseFirstMonth = JSON.parse(response.body)
		end
		second_month_request.on_complete do |response|
			json_responseSecondMonth = JSON.parse(response.body)
		end
		hydra.queue first_month_request
		hydra.queue second_month_request
		hydra.run


		dates = {}
		counter = 0
		json_responseFirstMonth["Quotes"].each do |quote| 
			quote_date = Date.parse(quote['Outbound_DepartureDate'])
			if(!dates.has_key? quote_date.month)
				dates[quote_date.month] = {}
			end
			#since we are caching requests we need to check to see if the date we are tracking is old
			if(quote_date >= Date.today)
				#if price already exists or new price is lower than existing price
				if(!dates[quote_date.month].has_key? quote_date.day or (dates[quote_date.month].has_key? quote_date.day and dates[quote_date.month][quote_date.day] > quote["Price"].to_i))
					dates[quote_date.month][quote_date.day] = quote["Price"].to_i
					counter += 1
				end
			end
		end
		json_responseSecondMonth["Quotes"].each do |quote| 
			quote_date = Date.parse(quote['Outbound_DepartureDate'])
			if(!dates.has_key? quote_date.month)
				dates[quote_date.month] = {}
			end
			if(counter > 30)
				break
			end
			#since we are caching requests we need to check to see if the date we are tracking is old
			if(quote_date >= Date.today)
				#if price already exists or new price is lower than existing price
				if(!dates[quote_date.month].has_key? quote_date.day or (dates[quote_date.month].has_key? quote_date.day and dates[quote_date.month][quote_date.day] > quote["Price"].to_i))
					dates[quote_date.month][quote_date.day] = quote["Price"].to_i
					counter += 1
				end
			end
		end
		return dates
	end

















	def getmockdata(month)

		json_responseFirstMonth = JSON.parse('{"Calendar":[{"CalendarId":1,"Date":"2015-05-13","Direct":true},{"CalendarId":2,"Date":"2015-05-14","Direct":true},{"CalendarId":3,"Date":"2015-05-15","Direct":true},{"CalendarId":4,"Date":"2015-05-16","Direct":true},{"CalendarId":5,"Date":"2015-05-17","Direct":true},{"CalendarId":6,"Date":"2015-05-18","Direct":true},{"CalendarId":7,"Date":"2015-05-19","Direct":true},{"CalendarId":8,"Date":"2015-05-20","Direct":true},{"CalendarId":9,"Date":"2015-05-21","Direct":true},{"CalendarId":10,"Date":"2015-05-22","Direct":true},{"CalendarId":11,"Date":"2015-05-23","Direct":true},{"CalendarId":12,"Date":"2015-05-24","Direct":true},{"CalendarId":13,"Date":"2015-05-25","Direct":true},{"CalendarId":14,"Date":"2015-05-26","Direct":true},{"CalendarId":15,"Date":"2015-05-27","Direct":true},{"CalendarId":16,"Date":"2015-05-28","Direct":true},{"CalendarId":17,"Date":"2015-05-29","Direct":true},{"CalendarId":18,"Date":"2015-05-30","Direct":true},{"CalendarId":19,"Date":"2015-05-31","Direct":true}],"Quotes":[{"CalendarId":1,"Price":222.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["vrda"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-13T00:00:00","Outbound_QuoteDateTime":"2015-05-13T21:06:00"},{"CalendarId":2,"Price":222.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["vrda"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-14T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:47:00"},{"CalendarId":3,"Price":216.2299,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-15T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:58:00"},{"CalendarId":4,"Price":205.4299,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-16T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:24:00"},{"CalendarId":5,"Price":211.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-17T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:25:00"},{"CalendarId":6,"Price":205.4299,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-18T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:50:00"},{"CalendarId":7,"Price":81.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-19T00:00:00","Outbound_QuoteDateTime":"2015-05-14T00:28:00"},{"CalendarId":8,"Price":168.1399,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-20T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:00:00"},{"CalendarId":9,"Price":170.1694,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-21T00:00:00","Outbound_QuoteDateTime":"2015-05-13T15:55:00"},{"CalendarId":10,"Price":168.1399,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-22T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:12:00"},{"CalendarId":11,"Price":140.6599,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-23T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:14:00"},{"CalendarId":12,"Price":140.6599,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-24T00:00:00","Outbound_QuoteDateTime":"2015-05-13T16:55:00"},{"CalendarId":13,"Price":79.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-25T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:23:00"},{"CalendarId":14,"Price":79.0999,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-26T00:00:00","Outbound_QuoteDateTime":"2015-05-14T04:57:00"},{"CalendarId":15,"Price":74.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-27T00:00:00","Outbound_QuoteDateTime":"2015-05-13T23:05:00"},{"CalendarId":16,"Price":74.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-28T00:00:00","Outbound_QuoteDateTime":"2015-05-13T21:27:00"},{"CalendarId":17,"Price":75.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-29T00:00:00","Outbound_QuoteDateTime":"2015-05-13T16:47:00"},{"CalendarId":18,"Price":74.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-30T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:49:00"},{"CalendarId":19,"Price":76.0064,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-05-31T00:00:00","Outbound_QuoteDateTime":"2015-05-12T19:56:00"}],"Places":[{"PlaceId":"LAX","IataCityCode":"LAX","IataAirportCode":"LAX","Name":"Los Angeles International","RegionId":"CA","CityName":"Los Angeles","CountryName":"United States","Type":"Station","CityId":"LAXA"},{"PlaceId":"SFO","IataCityCode":"SFO","IataAirportCode":"SFO","Name":"San Francisco International","RegionId":"CA","CityName":"San Francisco","CountryName":"United States","Type":"Station","CityId":"SFOA"}],"Carriers":[{"CarrierId":"UA","Name":"United","IcaoCode":"UAL","IataCode":"UA"},{"CarrierId":"US","Name":"US Airways","IcaoCode":"USA","IataCode":"US"},{"CarrierId":"VX","Name":"Virgin America","IcaoCode":"VRD","IataCode":"VX"}],"Agents":[{"AgentId":"farm","Name":"BookAirFare"},{"AgentId":"uair","Name":"United"},{"AgentId":"vrda","Name":"Virgin America"}],"Metadata":{"MachineName":"FLPVWUK2IDS012","Revision":"1.0.4039.426","ExperimentAssignments":[{"Experiment":"INDS_b1b3","Variant":"Treatment"}],"Properties":[{"Name":"Browse Service Average Quote Age","Value":30733},{"Name":"Browse Service Node","Value":"FLPVWUK2IDS012"},{"Name":"Browse Service Version","Value":"1.0.4039.426"}]}}') 
		json_responseSecondMonth = JSON.parse('{"Calendar":[{"CalendarId":1,"Date":"2015-06-01","Direct":true},{"CalendarId":2,"Date":"2015-06-02","Direct":true},{"CalendarId":3,"Date":"2015-06-03","Direct":true},{"CalendarId":4,"Date":"2015-06-04","Direct":true},{"CalendarId":5,"Date":"2015-06-05","Direct":true},{"CalendarId":6,"Date":"2015-06-06","Direct":true},{"CalendarId":7,"Date":"2015-06-07","Direct":true},{"CalendarId":8,"Date":"2015-06-08","Direct":true},{"CalendarId":9,"Date":"2015-06-09","Direct":true},{"CalendarId":10,"Date":"2015-06-10","Direct":true},{"CalendarId":11,"Date":"2015-06-11","Direct":true},{"CalendarId":12,"Date":"2015-06-12","Direct":true},{"CalendarId":13,"Date":"2015-06-13","Direct":true},{"CalendarId":14,"Date":"2015-06-14","Direct":true},{"CalendarId":15,"Date":"2015-06-15","Direct":true},{"CalendarId":16,"Date":"2015-06-16","Direct":true},{"CalendarId":17,"Date":"2015-06-17","Direct":true},{"CalendarId":18,"Date":"2015-06-18","Direct":true},{"CalendarId":19,"Date":"2015-06-19","Direct":true},{"CalendarId":20,"Date":"2015-06-20","Direct":true},{"CalendarId":21,"Date":"2015-06-21","Direct":true},{"CalendarId":22,"Date":"2015-06-22","Direct":true},{"CalendarId":23,"Date":"2015-06-23","Direct":true},{"CalendarId":24,"Date":"2015-06-24","Direct":true},{"CalendarId":25,"Date":"2015-06-25","Direct":true},{"CalendarId":26,"Date":"2015-06-26","Direct":true},{"CalendarId":27,"Date":"2015-06-27","Direct":true},{"CalendarId":28,"Date":"2015-06-28","Direct":true},{"CalendarId":29,"Date":"2015-06-29","Direct":true},{"CalendarId":30,"Date":"2015-06-30","Direct":true}],"Quotes":[{"CalendarId":1,"Price":74.0332,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-01T00:00:00","Outbound_QuoteDateTime":"2015-05-14T01:37:00"},{"CalendarId":2,"Price":72.1911,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ontr"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-02T00:00:00","Outbound_QuoteDateTime":"2015-05-07T09:07:00"},{"CalendarId":3,"Price":72.0350,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-03T00:00:00","Outbound_QuoteDateTime":"2015-05-13T16:46:00"},{"CalendarId":4,"Price":72.6070,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-04T00:00:00","Outbound_QuoteDateTime":"2015-05-14T08:38:00"},{"CalendarId":5,"Price":72.0350,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-05T00:00:00","Outbound_QuoteDateTime":"2015-05-14T11:22:00"},{"CalendarId":6,"Price":72.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-06T00:00:00","Outbound_QuoteDateTime":"2015-05-14T17:52:00"},{"CalendarId":7,"Price":75.1000,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-07T00:00:00","Outbound_QuoteDateTime":"2015-05-14T17:31:00"},{"CalendarId":8,"Price":74.1052,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-08T00:00:00","Outbound_QuoteDateTime":"2015-05-14T09:43:00"},{"CalendarId":9,"Price":72.9043,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-09T00:00:00","Outbound_QuoteDateTime":"2015-05-12T21:54:00"},{"CalendarId":10,"Price":72.0350,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-10T00:00:00","Outbound_QuoteDateTime":"2015-05-13T17:34:00"},{"CalendarId":11,"Price":72.0350,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-11T00:00:00","Outbound_QuoteDateTime":"2015-05-14T15:24:00"},{"CalendarId":12,"Price":73.4893,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-12T00:00:00","Outbound_QuoteDateTime":"2015-05-14T09:12:00"},{"CalendarId":13,"Price":75.5865,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-13T00:00:00","Outbound_QuoteDateTime":"2015-05-11T22:27:00"},{"CalendarId":14,"Price":77.6267,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ontr"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-14T00:00:00","Outbound_QuoteDateTime":"2015-05-12T05:11:00"},{"CalendarId":15,"Price":73.4893,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-15T00:00:00","Outbound_QuoteDateTime":"2015-05-14T10:15:00"},{"CalendarId":16,"Price":90.9232,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ffus"],"Outbound_CarrierIds":["WN"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-16T00:00:00","Outbound_QuoteDateTime":"2015-05-13T03:44:00"},{"CalendarId":17,"Price":72.6230,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-17T00:00:00","Outbound_QuoteDateTime":"2015-05-07T16:52:00"},{"CalendarId":18,"Price":72.0350,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-18T00:00:00","Outbound_QuoteDateTime":"2015-05-14T07:55:00"},{"CalendarId":19,"Price":72.0350,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-19T00:00:00","Outbound_QuoteDateTime":"2015-05-14T02:10:00"},{"CalendarId":20,"Price":89.9388,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ffus"],"Outbound_CarrierIds":["WN"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-20T00:00:00","Outbound_QuoteDateTime":"2015-05-14T14:16:00"},{"CalendarId":21,"Price":117.3953,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["vrda"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-21T00:00:00","Outbound_QuoteDateTime":"2015-05-12T18:48:00"},{"CalendarId":22,"Price":75.0644,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-22T00:00:00","Outbound_QuoteDateTime":"2015-05-14T14:18:00"},{"CalendarId":23,"Price":72.3954,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-23T00:00:00","Outbound_QuoteDateTime":"2015-05-14T07:50:00"},{"CalendarId":24,"Price":73.1447,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["farm"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-24T00:00:00","Outbound_QuoteDateTime":"2015-05-10T23:42:00"},{"CalendarId":25,"Price":97.7383,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ontr"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-25T00:00:00","Outbound_QuoteDateTime":"2015-05-06T07:01:00"},{"CalendarId":26,"Price":117.3953,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ontr"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-26T00:00:00","Outbound_QuoteDateTime":"2015-05-13T04:18:00"},{"CalendarId":27,"Price":89.9388,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["ffus"],"Outbound_CarrierIds":["WN"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-27T00:00:00","Outbound_QuoteDateTime":"2015-05-14T09:58:00"},{"CalendarId":28,"Price":112.7513,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["bfus"],"Outbound_CarrierIds":["US"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-28T00:00:00","Outbound_QuoteDateTime":"2015-05-09T04:52:00"},{"CalendarId":29,"Price":84.3306,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["edus"],"Outbound_CarrierIds":["VX"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-29T00:00:00","Outbound_QuoteDateTime":"2015-05-02T18:37:00"},{"CalendarId":30,"Price":76.4807,"CurrencyId":"USD","Direct":true,"Outbound_AgentIds":["uair"],"Outbound_CarrierIds":["UA"],"Outbound_FromStationId":"LAX","Outbound_ToStationId":"SFO","Outbound_DepartureDate":"2015-06-30T00:00:00","Outbound_QuoteDateTime":"2015-05-11T19:24:00"}],"Places":[{"PlaceId":"LAX","IataCityCode":"LAX","IataAirportCode":"LAX","Name":"Los Angeles International","RegionId":"CA","CityName":"Los Angeles","CountryName":"United States","Type":"Station","CityId":"LAXA"},{"PlaceId":"SFO","IataCityCode":"SFO","IataAirportCode":"SFO","Name":"San Francisco International","RegionId":"CA","CityName":"San Francisco","CountryName":"United States","Type":"Station","CityId":"SFOA"}],"Carriers":[{"CarrierId":"UA","Name":"United","IcaoCode":"UAL","IataCode":"UA"},{"CarrierId":"US","Name":"US Airways","IcaoCode":"USA","IataCode":"US"},{"CarrierId":"VX","Name":"Virgin America","IcaoCode":"VRD","IataCode":"VX"},{"CarrierId":"WN","Name":"Southwest Airlines","IcaoCode":"SWA","IataCode":"WN"}],"Agents":[{"AgentId":"bfus","Name":"Bravofly"},{"AgentId":"edus","Name":"eDreams"},{"AgentId":"farm","Name":"BookAirFare"},{"AgentId":"ffus","Name":"Flyfar"},{"AgentId":"ontr","Name":"OneTravel"},{"AgentId":"uair","Name":"United"},{"AgentId":"vrda","Name":"Virgin America"}],"Metadata":{"MachineName":"FLPVWNL1IDS003","Revision":"1.0.4039.426","ExperimentAssignments":[{"Experiment":"INDS_b1b3","Variant":"Treatment"}],"Properties":[{"Name":"Browse Service Average Quote Age","Value":190079},{"Name":"Browse Service Node","Value":"FLPVWNL1IDS003"},{"Name":"Browse Service Version","Value":"1.0.4039.426"}]}}')
		return month==1?json_responseFirstMonth:(json_responseSecondMonth)
	end

end

