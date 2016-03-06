class Transportation < ActiveRecord::Base
	has_and_belongs_to_many :locations
	has_many :primary_transportations

	def html_attributes
		attr_map = {}
		attr_map['name'] = self.name
		attr_map['id'] = self.id	
		attr_map['ranges'] = self.cost_ranges
		return attr_map
	end

	rails_admin do
		configure :cost_ranges,:pg_string_array
	end
end
