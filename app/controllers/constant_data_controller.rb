class ConstantDataController < ApplicationController
  
  def get_airports_api
    render :text => ENV['AIRPORT_CODES_API']
  end

	def get_all_accommodations
		@accommodations = Accommodation.all
		accommodation_list =[] 
		@accommodations.each do |accommodation|
			accommodation_list << accommodation.html_attributes
		end
		render :json => accommodation_list
	end

	def get_all_food_options
		@food_options = FoodOption.all
		food_option_list =[] 
		@food_options.each do |food_option|
			food_option_list << food_option.html_attributes
		end
		render :json => food_option_list
	end

	def get_all_transportations
		@transportations = Transportation.all
		transportation_list =[] 
		@transportations.each do |transportation|
			transportation_list << transportation.html_attributes
		end
		render :json => transportation_list
	end
end
