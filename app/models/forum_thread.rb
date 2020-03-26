class ForumThread < ActiveRecord::Base
	belongs_to :category
  belongs_to :user
  has_many :posts
  
  def self.createThread(subject, user_id, category_id)
    newThread = self.find_or_create_by(subject: subject, user_id: user_id, category_id: category_id)
    if newThread.id.nil?
      newThread.save!
    end

    newThread
  end
end
