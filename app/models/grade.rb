class Grade < ActiveRecord::Base
	belongs_to :climbing_type

	def html_attributes
		attr_map = {}
		attr_map['type'] = self.climbing_type.html_attributes
		attr_map['grade'] = self.us
		if !self.french.nil?
			if self.climbing_type.name == 'Ice'
				attr_map['grade'] = attr_map['grade']
			else
				attr_map['grade'] = attr_map['grade'] + '|' + self.french
			end
		end
		if !self.uiaa.nil?
			#attr_map['grade'] = attr_map['grade'] + '|' + self.uiaa
		end
		if !self.australian.nil?
			#attr_map['grade'] = attr_map['grade'] + '|' + self.australian
		end
		if !self.uk.nil?
			#attr_map['grade'] = attr_map['grade'] + '|' + self.uk
		end
		attr_map['id'] = self.id	
		return attr_map
	end

	def custom_label_method
		"#{self.us} - #{self.climbing_type.name}"
	end
	rails_admin do
		object_label_method do
			:custom_label_method
		end
	end
end
