class AddLocationEdit < ActiveRecord::Migration
  def change
		create_table :location_edits do |t|
			t.belongs_to :location, index: true
			t.string :edit_type
			t.json :edit
			t.boolean :approved, default: false

			t.timestamps
		end
  end
end
