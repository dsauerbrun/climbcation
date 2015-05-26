class AddNumericToSeasons < ActiveRecord::Migration
  def change
		add_column :seasons,:numerical_value, :integer
  end
end
