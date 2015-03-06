class RemoveLocationAssociations < ActiveRecord::Migration
  def change
		remove_column :climbing_types,:location_id, :integer
		remove_column :seasons,:location_id, :integer
		remove_column :accommodations,:location_id, :integer
  end
end
