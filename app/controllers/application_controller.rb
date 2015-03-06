class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
	def index
		@climbtypes = ClimbingType.all
		@locations = Location.order('name ASC').all
		@continents = @locations.pluck(:continent).uniq
	end
end
