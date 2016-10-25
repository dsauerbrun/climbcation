require 'uri'

class ExternalServicesController < ApplicationController
	class AirportCache
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

  def airports
    puts params
    Typhoeus::Config.cache = AirportCache.new
    response = Typhoeus.get("https://iatacodes.org/api/v6/autocomplete?api_key=275fbaf3-55c1-4c59-bffe-29f441684e07&query=#{URI.encode(params[:search])}", followlocation: true)

		if response.body.is_a?(String) and valid_json?(response.body)
      json_parse = JSON.parse(response.body)
      json_parse = json_parse['response']['airports']
    else
      json_parse = []
    end
		render :json => json_parse
  end

end
