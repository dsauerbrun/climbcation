class ApplicationController < ActionController::API
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
	#
	
	before_filter :cors_preflight_check
	after_filter :cors_set_access_control_headers

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
  	if request.method == :options
	  	headers['Access-Control-Allow-Origin'] = '*'
	    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
	    headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
	    headers['Access-Control-Max-Age'] = '1728000'
	    render :text => '', :content_type => 'text/plain'
	  end
	end
	
	def filters
		@climbtypes = ClimbingType.all
		@locations = Location.order('name ASC').all
		@continents = @locations.pluck(:continent).uniq
		filters = {}
		filters['climbTypes'] = {}
		filters['continents'] = []	
		@climbtypes.each do |type|
			filters['climbTypes'][type.id] = type.icon 
		end
		@continents.each do |continent|
			filters['continents'] << continent 
		end
		render :json => filters 
	end

	def index
		@climbtypes = ClimbingType.all
		@locations = Location.order('name ASC').all
		@continents = @locations.pluck(:continent).uniq
	end
end
