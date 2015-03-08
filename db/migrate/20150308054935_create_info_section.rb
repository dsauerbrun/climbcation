class CreateInfoSection < ActiveRecord::Migration
  def change
    create_table :info_sections do |t|
			t.string :title
			t.text :body
			t.json :metadata
			t.belongs_to :location, index: true
    end
  end
end
