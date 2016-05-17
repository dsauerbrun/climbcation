class FoodOptionLocationDetail < ActiveRecord::Base
	has_paper_trail
	belongs_to :location
	belongs_to :food_option
end
