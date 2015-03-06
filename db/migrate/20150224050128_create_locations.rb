class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
			t.string :continent
			t.string :name
			t.belongs_to :grade, index: true
			t.string :latitude
			t.string :longitude
			t.money :price_range_floor
			t.money :price_range_ceiling

      t.timestamps
    end
  end
end
