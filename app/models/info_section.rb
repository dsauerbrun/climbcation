class InfoSection < ActiveRecord::Base
	has_paper_trail
	belongs_to :location

	def self.create_new_info_section(locationId, section)
		location = Location.find(locationId)	
		if section['title'] != ''
			metadata = {}
			section['subsections'].each do |subsection|
				if subsection['title'] != ''
					metadata[subsection['title']] = []
					subsection['subsectionDescriptions'].each do |subsectionDescription|
						if subsectionDescription['desc'] != ''
							metadata[subsection['title']].push({'desc' => subsectionDescription['desc']})
						end
					end
				end
			end
			infosect = InfoSection.create!(title: section['title'], body: section['body'], metadata: metadata)
			location.info_sections << infosect
		end
	end
end
