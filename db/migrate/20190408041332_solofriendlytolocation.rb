class Solofriendlytolocation < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :solo_friendly, :boolean, :default => false
  end
end
