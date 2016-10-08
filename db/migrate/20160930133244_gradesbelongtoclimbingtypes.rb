class Gradesbelongtoclimbingtypes < ActiveRecord::Migration
  def change
			add_reference :grades, :climbing_type, index: true
  end
end
