class CreateClimbingTypes < ActiveRecord::Migration
  def change
    create_table :climbing_types do |t|
			t.string :type

      t.timestamps
    end
  end
end
