class LocationRedesignFields < ActiveRecord::Migration
  def change
		add_column :locations, :closest_accommodation, :string
		add_column :locations, :walking_distance, :boolean
		add_column :locations, :getting_in_notes, :text
		add_column :locations, :accommodation_notes, :text
		add_column :locations, :common_expenses_notes, :text
		add_column :locations, :saving_money_tips, :text
  end
end
