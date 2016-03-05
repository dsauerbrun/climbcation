class FoodOptionLocationDetails < ActiveRecord::Migration
  def change
		create_table :food_option_location_details do |t|
			t.belongs_to :location, index: true
			t.belongs_to :food_option, index: true
			t.string :cost

			t.timestamps
		end
  end
end
