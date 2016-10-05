class LocationsHaveManyGrades < ActiveRecord::Migration
  def change
		create_table :grades_locations, id: false do |t|
			t.belongs_to :location, index: true
			t.belongs_to :grade, index: true
		end
  end
end
