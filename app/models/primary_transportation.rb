class PrimaryTransportation < ActiveRecord::Base
	belongs_to :location
	belongs_to :transportation
end
