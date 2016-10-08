class SwitchGradesOver < ActiveRecord::Migration
  def up
		#get all locations with just bouldering as the climbing type, take the grade and insert it into grades
		#get all locations with just sport as the climbing type, take the grade and insert it into grades
		#get all locations with just trad as the climbing type, find the same grade with trad as the climbing type and insert that into grades
		#get all locations with just alpine as the climbing type, find the same grade with trad as the climbing type and insert that into grades
		#
		#
		#
		#
		# ice and dws need to be done separately
		# locations with more than one climbing type need to be done separately too
		#
		#
		#

		trad = ClimbingType.where(:name => 'Trad').first
		alpine = ClimbingType.where(:name => 'Alpine').first
		bouldering_locations = Location.all.select { |location| location.climbing_types.size == 1 && location.climbing_types[0].name == "Bouldering"  }
		sport_locations = Location.all.select { |location| location.climbing_types.size == 1 && location.climbing_types[0].name == "Sport"  }
		trad_locations = Location.all.select { |location| location.climbing_types.size == 1 && location.climbing_types[0].name == "Trad"  }
		alpine_locations = Location.all.select { |location| location.climbing_types.size == 1 && location.climbing_types[0].name == "Alpine"  }

		bouldering_locations.each do |location|
			location.grades << location.grade
			location.save
		end
		sport_locations.each do |location|
			location.grades << location.grade
			location.save
		end
		trad_locations.each do |location|
			us_grade = location.grade.us
			found_grade = Grade.where(:us => us_grade).where(:climbing_type => trad)
			location.grades << found_grade
			location.save
		end
		alpine_locations.each do |location|
			us_grade = location.grade.us
			found_grade = Grade.where(:us => us_grade).where(:climbing_type => alpine)
			location.grades << found_grade
			location.save
		end
  end

  def down 
  end
end
