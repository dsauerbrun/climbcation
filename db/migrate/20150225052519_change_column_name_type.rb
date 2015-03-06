class ChangeColumnNameType < ActiveRecord::Migration
  def self.up
		rename_column :accommodations, :type, :name
		rename_column :climbing_types, :type, :name
  end
  def self.down
		rename_column :accommodations, :name, :type
		rename_column :climbing_types, :name, :type
  end
end
