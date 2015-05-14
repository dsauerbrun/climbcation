class AddAirportCodeToLocation < ActiveRecord::Migration
  def change
		add_column :locations, :airport_code, :string
  end
end
