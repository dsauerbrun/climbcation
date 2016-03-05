class FoodOptionLocationDetail < ActiveRecord::Base
	belongs_to :location
	belongs_to :food_option
end
