class User < ActiveRecord::Base
  def validate_password
  end

  def self.create_with_omniauth(auth)
    puts auth.inspect
    user = nil
    if auth["provider"] == "facebook"
      user = self.find_or_create_by(uid: auth["uid"], provider:  auth["provider"])
      user.email = "#{auth["uid"]}@#{auth["provider"]}.com"
      user.password = auth["uid"]
      user.username = auth["info"]["name"]
      puts user.inspect
    elsif auth["provider"] == "google_oauth2"
      user = self.find_or_create_by(uid: auth["uid"], provider:  auth["provider"])
      user.email = auth["info"]["email"]
      user.password = auth["uid"]
      user.username = auth["info"]["name"]
      user.google_token = auth.credentials.token
      refresh_token = auth.credentials.refresh_token
      user.google_refresh_token = refresh_token if refresh_token.present?
      puts user.inspect

    end
    user.save!
    user
  end 
end
