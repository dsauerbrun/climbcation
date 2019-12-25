class Users < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
			t.string :provider
      t.string :uid
      t.string :oauth_token
      t.datetime :oauth_expires_at
      t.string :username
      t.string :password
      t.string :email
      t.string :google_token
      t.string :google_refresh_token

      t.timestamps
    end
  end
end
