class CreateGrades < ActiveRecord::Migration
  def change
    create_table :grades do |t|
			t.string :us
			t.string :french
			t.string :australian
			t.string :south_african
			t.string :uiaa
			t.string :uk

      t.timestamps
    end
  end
end
