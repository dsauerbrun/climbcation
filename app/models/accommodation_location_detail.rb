class AccommodationLocationDetail < ActiveRecord::Base
	has_paper_trail
	belongs_to :location
	belongs_to :accommodation
end
