class Grade < ActiveRecord::Base
	belongs_to :climbing_type

	def html_attributes
		attr_map = {}
		attr_map['type'] = self.climbing_type.html_attributes
		attr_map['grade'] = self.combine_grade
		attr_map['id'] = self.id	
		return attr_map
	end

  def combine_grade
    readable = self.us
		if !self.french.nil?
			if self.climbing_type.name != 'Ice'
				readable = readable + '|' + self.french
			end
		end
    return readable
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
