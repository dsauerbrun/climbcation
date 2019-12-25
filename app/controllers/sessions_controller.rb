class SessionsController < ApplicationController

  def get
    if session[:user_id].nil?
      render status: 200, plain: '', :content_type => 'text/plain'
    else
      render status: 200, json: session  
    end  
  end

  def create
    if request.env["omniauth.auth"]
      user = User.create_with_omniauth(request.env["omniauth.auth"])
      session[:user_id] = user.id
      session[:username] = user.username
      #render :json => {} 
      redirect_to root_path
    else
      user = User.create_with_self(params[:email], params[:username], params[:password])
      user.send_registration_verification()
      session[:user_id] = user.id
      session[:username] = user.username
      render status: 200, json: session
    end
  end

  #our own login method when they put in username/pass
  def login

      user = User.find_by_email(params[:username])
      if user.nil? || (user && user.authenticate(params[:password]) == false)
        render status: 400, json: nil 
      else
        session[:user_id] = user.id
        session[:username] = user.username
        render status: 200, json: session
      end
  end

  def destroy
    session[:user_id] = nil
    session[:username] = nil
    session[:session_id] = nil
    redirect_to root_path
  end


  def verify_email
    user = User.find_by_verify_token(params[:id])
    if user
      user.verify_email
    end
    redirect_to root_url
  end


  

  def failure
  end
end
