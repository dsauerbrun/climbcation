class AddOrderToGrades < ActiveRecord::Migration
  def change
		add_column :grades, :order, :integer
  end
end
