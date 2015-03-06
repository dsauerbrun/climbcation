class AddIcons < ActiveRecord::Migration
  def self.up 
		add_attachment :seasons, :icon
		add_attachment :accommodations, :icon
		add_attachment :climbing_types, :icon
  end
  def self.down 
		remove_attachment :seasons, :icon
		remove_attachment :accommodations, :icon
		remove_attachment :climbing_types, :icon
  end
end
