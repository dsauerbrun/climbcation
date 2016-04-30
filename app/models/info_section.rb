class InfoSection < ActiveRecord::Base
	has_paper_trail
	belongs_to :location

	def self.create_new_info_section(locationId, section)
		location = Location.find(locationId)	
		if section['title'] != ''
			infosect = InfoSection.create!(title: section['title'], body: section['body'])
			location.info_sections << infosect
			return infosect
		end
	end
end
