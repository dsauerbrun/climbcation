class AddSubmitterEmailToLocation < ActiveRecord::Migration
  def change
		add_column :locations,:submitter_email, :string
  end
end
