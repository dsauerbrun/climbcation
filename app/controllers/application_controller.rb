class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
	#
	
	before_action :cors_preflight_check
	after_action :cors_set_access_control_headers

	# For all responses in this controller, return the CORS access control headers.
	
	def cors_set_access_control_headers
	  headers['Access-Control-Allow-Origin'] = '*'
	  headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	  headers['Access-Control-Max-Age'] = "1728000"
	end
	
	#       # If this is a preflight OPTIONS request, then short-circuit the
	#       # request, return only the necessary headers and return an empty
	#       # text/plain.
	
  def cors_preflight_check
		response.headers['Access-Control-Allow-Origin'] = request.headers['Origin'] || '*'
		response.headers['Access-Control-Allow-Credentials'] = 'true' 
  	if request.method == :options
	  	headers['Access-Control-Allow-Origin'] = '*'
	    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	    headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
	    headers['Access-Control-Max-Age'] = '1728000'
	    render plain: '', :content_type => 'text/plain'
	  end
	end

	def options
		head :status => 200, :'Access-Control-Allow-Headers' => 'accept, content-type'
	end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end
  helper_method :current_user
	
	def filters
		@climbtypes = ClimbingType.all
    @grades = Grade.all.order('grades.order ASC')
		filters = {
      climbTypes: [],
      grades: [],
    }

		@climbtypes.each do |type|
      filters[:climbTypes] << {type: type.name, url: type.icon} 
		end
		@grades.each do |grade|
      existingType = filters[:grades].find { |i| i[:climbing_type] == grade.climbing_type.name }
      if existingType.nil?
        existingType = {
          climbing_type: grade.climbing_type.name,
          climb_type_id: grade.climbing_type.id,
          grades: [],
          type_html: grade.climbing_type.html_attributes
        }
        filters[:grades] << existingType
      end
      existingType[:grades] << {id: grade.id, grade: grade.combine_grade, climbing_type: grade.climbing_type.name, order: grade.order, typeId: grade.climbing_type.id}
		end
		render :json => filters 
	end

	def get_attribute_options
		attributes = {}
		attributes['climbing_types'] = []
		attributes['accommodations'] = []
		attributes['months'] = []
		attributes['grades'] = []
		attributes['food_options'] = []
		attributes['transportations'] = []
		Accommodation.all.each do |accommodation|
			attributes['accommodations'].push(accommodation.html_attributes)
		end
		FoodOption.all.each do |food|
			attributes['food_options'].push(food.html_attributes)
		end
		Transportation.all.each do |transport|
			attributes['transportations'].push(transport.html_attributes)
		end
		Season.order(:numerical_value).all.each do |season|
			attributes['months'].push(season.html_attributes)
		end
		ClimbingType.all.each do |type|
			attributes['climbing_types'].push(type.html_attributes)
		end
    Grade.order('grades.order desc').all.each do |grade|
			attributes['grades'].push(grade.html_attributes)
		end
		render :json => attributes
	end

	def index
		@climbtypes = ClimbingType.all
		@locations = Location.where(active: true).order('name ASC').all
		@continents = @locations.pluck(:continent).uniq
	end

	def home
          render :file => "public/angularapp/index.html"
	end
end
