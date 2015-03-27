class Location < ActiveRecord::Base
	validates_presence_of :slug
	belongs_to :grade
	has_and_belongs_to_many :climbing_types
	has_and_belongs_to_many :seasons
	has_and_belongs_to_many :accommodations
	has_many :info_sections
	 
	has_attached_file :home_thumb, :default_url => "/images/:style/missing.png"
	validates_attachment_content_type :home_thumb, :content_type => /\Aimage\/.*\Z/
	def continent_enum
		['Asia','Australia','North America', 'South America','Africa','Europe','Antarctica']
	end
	def to_param
		slug	
	end

end
