class CreateAccommodations < ActiveRecord::Migration
  def change
    create_table :accommodations do |t|
			t.string :type

      t.timestamps
    end
  end
end
