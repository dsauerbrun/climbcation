class AddBelongsToAssociationsForLocation < ActiveRecord::Migration
  def change
		add_column :climbing_types,:location_id, :integer
		add_index :climbing_types, :location_id
		add_column :seasons,:location_id, :integer
		add_index :seasons, :location_id
		add_column :accommodations,:location_id, :integer
		add_index :accommodations, :location_id
  end
end
