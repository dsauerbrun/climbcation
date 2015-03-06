class AddThumbToLocation < ActiveRecord::Migration
  def change
		add_attachment :locations, :home_thumb
  end
end
