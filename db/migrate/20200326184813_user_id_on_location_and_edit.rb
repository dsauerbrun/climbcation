class UserIdOnLocationAndEdit < ActiveRecord::Migration[5.2]
  def change
    add_reference :locations, :user, index: true
    add_reference :location_edits, :user, index: true
  end
end
