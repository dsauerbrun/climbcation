class LocationEdit < ActiveRecord::Base
	belongs_to :location
	belongs_to :user

	def approve
		if self.edit_type == 'misc'
                  self.location.change_sections(self.edit)
                elsif self.edit_type == 'accommodation'
                  self.location.change_accommodations(self.edit)	
                elsif self.edit_type == 'getting_in'
                  self.location.change_getting_in(self.edit)	
                elsif self.edit_type == 'food_options'
                  self.location.change_food_options(self.edit)	
		end
		self.approved = true
		self.save
	end
end
