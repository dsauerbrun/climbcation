def is_numeric(o)
  true if Integer(o) rescue false
end

class Post < ActiveRecord::Base
	has_paper_trail
	belongs_to :forum_thread
	belongs_to :user

  DestinationCategoryName = 'Destinations'

  def self.createNewPost(content, user_id, forum_thread_id)
    if !is_numeric(forum_thread_id)
      # must looks like this is a comment for a location so we need to get or create the thread
      categoryDestination = Category.find_by_name(DestinationCategoryName)
      forum_thread_id = ForumThread.createThread(forum_thread_id, 1, categoryDestination.id).id
    end 

    newPost = self.create(content: content, user_id: user_id, forum_thread_id: forum_thread_id)
    newPost
  end

  def edit(newContent, user_id)
    if (self.user_id == user_id)
      self.content = newContent
      self.save!
    else
      raise 'You do not have permissions to edit this comment.'
    end
  end
end
