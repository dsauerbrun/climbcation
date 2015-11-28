class InfoSectionsController < ApplicationController
	def update_info_section
		id = params[:id]
		section = params[:section]
		infosection = InfoSection.find(id)
		infosection.title = section[:title]
		infosection.body = section[:body]
		metadata = {}
=begin
		section[:subsections].each do |key,subsection|
			if subsection['title'] != ''
				metadata[subsection['title']] = []
				subsection['subsectionDescriptions'].each do |key, subsectionDescription|
					puts 'subsections ============='
					puts subsectionDescription
					if subsectionDescription['desc'] != ''
						metadata[subsection['title']].push({'desc' => subsectionDescription['desc']})
					end
				end
			end
		end
=end
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
