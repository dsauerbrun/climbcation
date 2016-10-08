class GenerateNewGradesAndAddTypes < ActiveRecord::Migration
  def up
	  types	= ClimbingType.all
		bouldering = types.find { |type| type.name == 'Bouldering' }
		ice = types.find { |type| type.name == 'Ice' }
		dws = types.find { |type| type.name == 'DWS' }
		alpine = types.find { |type| type.name == 'Alpine' }
	  trad = types.find { |type| type.name == 'Trad' }
	  sport = types.find { |type| type.name == 'Sport' }

		v_grades = Grade.where('us ILIKE \'%V%\'')
		v_grades.each do |grade| 
			grade.climbing_type = bouldering
			grade.save
		end
		
		yos_grades = Grade.where('us ILIKE \'5%\'')
		yos_grades.each do |grade|
			grade.climbing_type = sport
			grade.save
		end


		#add ice, dws, alpine, and trad grades
		yos_grades.each do |grade|
			puts grade.inspect
			Grade.create(:us => grade.us, :french => grade.french, :australian => grade.australian, :uiaa => grade.uiaa, :uk => grade.uk, :order => grade.order, :climbing_type => dws)
			Grade.create(:us => grade.us, :french => grade.french, :australian => grade.australian, :uiaa => grade.uiaa, :uk => grade.uk, :order => grade.order, :climbing_type => alpine)
			Grade.create(:us => grade.us, :french => grade.french, :australian => grade.australian, :uiaa => grade.uiaa, :uk => grade.uk, :order => grade.order, :climbing_type => trad)
		end

		ice_grades = [
			{num: 'WI1', order: 1},
			{num: 'M1', order: 1},
			{num: 'WI2', order: 2},
			{num: 'M2', order: 2},
			{num: 'WI3', order: 3},
			{num: 'M3', order: 3},
			{num: 'WI4', order: 4},
			{num: 'M4', order: 4},
			{num: 'WI5', order: 5},
			{num: 'M5', order: 5},
			{num: 'M6', order: 6},
			{num: 'M7', order: 7},
			{num: 'M8', order: 8},
			{num: 'M9', order: 9},
			{num: 'M10', order: 10},
			{num: 'M11', order: 11},
			{num: 'M12', order: 12},
			{num: 'M13', order: 13}
		]
		ice_grades.each do |grade|
			Grade.create(:us => grade[:num], :french => grade[:num], :australian => grade[:num], :uiaa => grade[:num], :uk => grade[:num], :order => grade[:order], :climbing_type => ice)
		end
  end
  def down 

  end
end
