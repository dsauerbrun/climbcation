class AccommodationLocationDetail < ActiveRecord::Base
	belongs_to :location
	belongs_to :accommodation
end
