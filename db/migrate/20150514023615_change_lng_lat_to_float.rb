class ChangeLngLatToFloat < ActiveRecord::Migration
  def change
		alter_column :locations, :longitude, :float, "USING CAST(latitude AS float)", 1
		alter_column :locations, :latitude, :float, "USING CAST(latitude AS float)", 1
  end

		def alter_column(table_name, column_name, new_type, mapping, default = nil)
		    drop_default = %Q{ALTER TABLE #{table_name} ALTER COLUMN #{column_name} DROP DEFAULT;}
		    execute(drop_default)
		    # puts drop_default
		 
		    base = %Q{ALTER TABLE #{table_name} ALTER COLUMN #{column_name} TYPE #{new_type} }
		    if mapping.kind_of?(Hash)
		      contains_else = mapping.has_key?("else")
		      else_mapping = mapping.delete("else")
		      when_mapping = mapping.map { |k, v| "when '#{k}' then #{v}" }.join("\n")
		      
		      base += %Q{ USING CASE #{column_name} #{when_mapping} } unless when_mapping.blank?
		      base += %Q{ ELSE #{else_mapping} } unless contains_else.blank?
		      base += %Q{ END } if !when_mapping.blank? or !contains_else.blank?
		    elsif mapping.kind_of?(String)
		      base += mapping
		    end
		    base += ";"
		    
		    execute(base);
		    # puts base
		    
		    unless default.blank?
		      set_default = %Q{ALTER TABLE #{table_name} ALTER COLUMN #{column_name} SET DEFAULT #{default};}
		      execute(set_default)
		      # puts set_default
	    	end
	  	end
end
