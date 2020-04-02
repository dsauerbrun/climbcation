class Vote < ActiveRecord::Base
	belongs_to :thread
	belongs_to :post
	belongs_to :user
end
