class FoodOption < ActiveRecord::Base
	has_many :food_option_location_details
end
