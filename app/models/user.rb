require 'net/smtp'

class User < ActiveRecord::Base
  before_create :verification_token

  def verify_email
    puts self.inspect
    self.verify_token = nil
    self.verified = true;
    self.save!
  end



  def confirm_email_user_url
    return "https://www.climbcation.com/verify?id=#{self.verify_token}"
  end

  def send_registration_verification 
		begin
      message = <<MESSAGE_END
From: Climbcation <no-reply@climbcation.com>
To: #{self.username} <#{self.email}>
MIME-Version: 1.0
Content-type: text/html
Subject: Please verify your email 

Hello #{self.username}, thanks for registering on Climbcation! To confirm your registration please click #{self.confirm_email_user_url}

MESSAGE_END
      smtp = Net::SMTP.new 'smtp.gmail.com', 587
			smtp.enable_starttls

			smtp.start('gmail.com', ENV['EMAIL_USER'], ENV['EMAIL_PASSWORD'], :plain) do |smtp|
        smtp.send_message message, 'no-reply@climbcation.com', self.email 
			end
		rescue => exception
			print exception.backtrace
		end
  end

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
  
  private
  def verification_token
    if self.verify_token.blank?
      self.verify_token = SecureRandom.urlsafe_base64.to_s
    end
  end
end
