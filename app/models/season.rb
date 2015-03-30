class Season < ActiveRecord::Base
	has_attached_file :icon, :url => ':s3_domain_url', :path => '/:class/:attachment/:id_partition/:style/:filename'
	validates_attachment_content_type :icon, :content_type => /\Aimage\/.*\Z/
	has_and_belongs_to_many :locations
end
