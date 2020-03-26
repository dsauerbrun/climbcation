class ForumController < ApplicationController
  DestinationCategoryName = 'Destinations' 
  def get_thread
    force_destination = params[:destination_category]
    if force_destination == 'true'
      destination_category = Category.find_by_name(DestinationCategoryName) 
      posts = Post 
        .select('posts.*', 'users.username')
        .joins(:forum_thread)
        .joins(:user)
        .where(forum_threads: {category_id: destination_category.id, subject: params[:id]}).order('posts.created_at desc')
    else
      posts = Post
        .select('posts.*', 'users.username')
        .joins(:forum_thread)
        .joins(:user)
        .where(forum_threads: {id: params[:id]}).order('posts.created_at desc')
    end
    render status: 200, json: posts
  end

  def post_comment
    if session[:user_id].nil?
      render status: 400, plain: 'Must be logged in to post a comment', :content_type => 'text/plain'
      return
    end

    if !session[:verified]
      render status: 400, plain: 'You must verify your account before you can post a comment. Please check your email for your verification link.', :content_type => 'text/plain'
      return
    end

    #check if user posted more than 5 posts in the last 30 seconds
    lastPosts = Post.where(created_at: 30.seconds.ago..DateTime.now, user_id: session[:user_id]);
    if lastPosts.length > 5
      render status: 400, plain: 'You cannot post more than 5 comments within 30 seconds. Please wait and try again.', :content_type => 'text/plain'
      return
    end

    #should probably have a check here to see if there have been over 30 comments in the last 1 second to see if we're being spammed
    post = Post.createNewPost(params[:content], session[:user_id], params[:id])

    render status: 200, json: post 
  end

end
