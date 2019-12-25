class SessionsController < ApplicationController

  def get
    if session[:user_id].nil?
      render status: 200, plain: '', :content_type => 'text/plain'
    else
      render status: 200, json: session  
    end  
  end

  def create
    puts 'here i am'
    if request.env["omniauth.auth"]
      user = User.create_with_omniauth(request.env["omniauth.auth"])
      session[:user_id] = user.id
      session[:username] = user.username
      render :json => {} 
    else
      user = User.find_by_email(params[:email])
      user && user.authenticate(params[:password])
      session[:user_id] = user.id
      session[:username] = user.username
      render status: 200
    end
  end

  def destroy
    session[:user_id] = nil
    session[:username] = nil
    session[:session_id] = nil
    redirect_to root_path
  end

  def failure
  end
end
