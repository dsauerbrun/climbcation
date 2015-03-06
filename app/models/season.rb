class Season < ActiveRecord::Base
	has_attached_file :icon, :default_url => "/images/:style/missing.png"
	validates_attachment_content_type :icon, :content_type => /\Aimage\/.*\Z/
	has_and_belongs_to_many :locations
end
