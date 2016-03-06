class AddCostRanges < ActiveRecord::Migration
  def change
		add_column :accommodations, :cost_ranges, :string, array: true
		add_column :transportations, :cost_ranges, :string, array: true
		add_column :food_options, :cost_ranges, :string, array: true
  end
end
