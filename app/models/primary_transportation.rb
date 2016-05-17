class PrimaryTransportation < ActiveRecord::Base
	has_paper_trail
	belongs_to :location
	belongs_to :transportation
end
