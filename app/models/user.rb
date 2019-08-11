class User < ActiveRecord::Base
  def validate_password
  end

  def self.create_with_omniauth(auth)
    user = self.find_or_create_by(uid: auth["uid"], provider:  auth["provider"])
    user.email = "#{auth["uid"]}@#{auth["provider"]}.com"
    user.password = auth["uid"]
    user.username = auth["info"]["name"]
    puts user.inspect
    user.save!
    user
  end 
end
