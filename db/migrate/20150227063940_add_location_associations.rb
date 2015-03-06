class AddLocationAssociations < ActiveRecord::Migration
  def change
		create_table :climbing_types_locations, id: false do |t|
			t.belongs_to :location, index: true
			t.belongs_to :climbing_type, index: true
		end
		create_table :locations_seasons, id: false do |t|
			t.belongs_to :location, index: true
			t.belongs_to :season, index: true
		end
		create_table :accommodations_locations, id: false do |t|
			t.belongs_to :location, index: true
			t.belongs_to :accommodation, index: true
		end
  end
end
