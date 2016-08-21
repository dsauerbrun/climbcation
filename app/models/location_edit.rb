class LocationEdit < ActiveRecord::Base
	belongs_to :location

	def approve
		if self.edit_type == 'misc'
			self.location.change_sections(self.edit)
		else
			self.location.change_accommodations(self.edit)	
			self.location.change_getting_in(self.edit)	
			self.location.change_food_options(self.edit)	
		end
		self.approved = true
		self.save
	end
end
