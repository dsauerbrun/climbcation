class InfoSection < ActiveRecord::Base
	has_paper_trail
	belongs_to :location
end
