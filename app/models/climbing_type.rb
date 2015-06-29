class ClimbingType < ActiveRecord::Base
	has_attached_file :icon, :default_url => "/images/:style/missing.png" 
	validates_attachment_content_type :icon, :content_type => /\Aimage\/.*\Z/
	has_and_belongs_to_many :locations

	def html_attributes
		attr_map = {}
		attr_map['url'] = self.icon.url
		attr_map['name'] = self.name
		attr_map['id'] = self.id	
		return attr_map
	end
end
