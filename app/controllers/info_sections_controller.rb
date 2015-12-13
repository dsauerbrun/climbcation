class InfoSectionsController < ApplicationController
	def update_info_section
		section = params[:section]
		if params[:id] == nil and params[:locationId] != nil
			locationId = params[:locationId]
			InfoSection.create_new_info_section(locationId, section)
			render :json => section
		else
			id = params[:id]
			infosection = InfoSection.find(id)
			infosection.title = section[:title]
			infosection.body = section[:body]
			metadata = {}
			section['subsections'].each do |title, subsection|
				if subsection['title'] != ''
					metadata[subsection['title']] = []
					subsection['subsectionDescriptions'].each do |subsectionDescription|
						puts subsectionDescription
						if subsectionDescription['desc'] != ''
							metadata[subsection['title']].push({'desc' => subsectionDescription['desc']})
						end
					end
				end
			end
			infosection.metadata = metadata 
			infosection.save
			render :json => section
		end
	end

end
