class Grade < ActiveRecord::Base
	has_many :locations

	def html_attributes
		attr_map = {}
		attr_map['grade'] = self.us
		attr_map['id'] = self.id	
		return attr_map
	end
end
