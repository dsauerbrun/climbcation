class Season < ActiveRecord::Base
	has_attached_file :icon, :default_url => "/images/:style/missing.png" 
	validates_attachment_content_type :icon, :content_type => /\Aimage\/.*\Z/
	has_and_belongs_to_many :locations

	def html_attributes
		attr_map = {}
		attr_map['name'] = self.name
		attr_map['id'] = self.id	
		attr_map['number'] = self.numerical_value	
		return attr_map
	end

end
