class SessionsController < ApplicationController

  def get
    if session[:user_id].nil?
      render status: 200, plain: '', :content_type => 'text/plain'
    else
      render status: 200, json: session  
    end  
  end

  def create
    puts 'hitting create'
    if request.env["omniauth.auth"]
      puts 'hitting create2'
      user = User.create_with_omniauth(request.env["omniauth.auth"])
      puts 'hitting create3'
      session[:user_id] = user.id
      puts 'hitting creat4'
      session[:username] = user.username
      puts 'hitting create5'
      puts params[:state]
      puts params[:callback_path]
      redirect_to root_path#params[:state]
    else
      user = User.find_by_email(params[:email])
      user || user = User.find_by_username(params[:username]) 
      if user
        render status: 400, plain: 'Email or Username is already in use.'
      else
        begin
          user = User.create_with_self(params[:email], params[:username], params[:password])
          user.send_registration_verification()
          session[:user_id] = user.id
          session[:username] = user.username
          render status: 200, json: session
        rescue StandardError => exception_string
          if exception_string.message == 'Password must be at least 6 characters long'
            render status: 400, plain: 'Password must be at least 6 characters long'
          else
            render status: 400, plain: 'Error creating account'
          end
        end
      end
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

  def reset_password
    user = User.find_by_email(params[:email])
    if user
      user.send_reset_password()
      render status: 200, json: nil
    else
      render status: 400, plain: 'This email does not exist.', :content_type => 'text/plain'
    end
  end

  def change_password
    user = User.find_by_verify_token(params[:id])
    
    if user
      begin
        user.change_password(params[:password])
        render status: 200, plain: '' 
      rescue StandardError => exception_string
        if exception_string.message == 'Password must be at least 6 characters long'
          render status: 400, plain: exception_string 
        else
          render status: 400, plain: 'Error creating account'
        end
      end
    else
      render status: 400, plain: 'This reset password link has expired.', :content_type => 'text/plain'
    end
  end
  

  def failure
  end
end
