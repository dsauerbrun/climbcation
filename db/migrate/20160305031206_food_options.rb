class FoodOptions < ActiveRecord::Migration
  def change
		create_table :food_options do |t|
			t.string :name
			t.timestamps
		end
  end
end
