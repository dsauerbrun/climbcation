class AccommodationLocationDetails < ActiveRecord::Migration
  def change
		create_table :accommodation_location_details do |t|
			t.belongs_to :location, index: true
			t.belongs_to :accommodation, index: true
			t.string :cost

			t.timestamps
		end
  end
end
