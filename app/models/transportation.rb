class Transportation < ActiveRecord::Base
	has_and_belongs_to_many :locations
	has_many :primary_transportations

	def html_attributes
		attr_map = {}
		attr_map['url'] = self.icon.url
		attr_map['name'] = self.name
		attr_map['id'] = self.id	
		return attr_map
	end

end
