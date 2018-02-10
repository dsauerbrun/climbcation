class AddRatingToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :rating, :integer, :default => 3
  end
end
