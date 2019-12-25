class User < ActiveRecord::Base

  def authenticate(password) 
    if BCrypt::Engine.hash_secret(password, self.password_salt) == self.password
      true
    else
      false
    end
  end

  def self.create_with_omniauth(auth)
    user = nil
    if auth["provider"] == "facebook"
      user = self.find_or_create_by(uid: auth["uid"], provider:  auth["provider"])
      user.email = "#{auth["uid"]}@#{auth["provider"]}.com"
      user.password = auth["uid"]
      user.username = auth["info"]["name"]
      user.verified = true;
    elsif auth["provider"] == "google_oauth2"
      user = self.find_or_create_by(uid: auth["uid"], provider:  auth["provider"])
      user.email = auth["info"]["email"]
      user.password = auth["uid"]
      user.username = auth["info"]["name"]
      user.google_token = auth.credentials.token
      refresh_token = auth.credentials.refresh_token
      user.google_refresh_token = refresh_token if refresh_token.present?
      user.verified = true;

    end
    user.save!
    user
  end 

  def self.create_with_self(email, username, password)
    salt = BCrypt::Engine.generate_salt
    salted_password = BCrypt::Engine.hash_secret(password, salt)
    user = self.find_or_create_by(provider: 'self', username: username, email: email, password_salt: salt, password: salted_password)

    user.save!
    user
  end
end