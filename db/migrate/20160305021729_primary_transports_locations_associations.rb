class PrimaryTransportsLocationsAssociations < ActiveRecord::Migration
  def change
		create_table :locations_transportations, id: false do |t|
			t.belongs_to :location, index: true
			t.belongs_to :transportation, index: true
		end
    create_table :primary_transportations do |t|
			t.belongs_to :transportation, index: true
			t.belongs_to :location, index: true, uniqueness: true
			t.string :cost

      t.timestamps
    end
  end
end
