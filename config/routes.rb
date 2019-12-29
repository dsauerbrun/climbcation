Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  #root 'application#index'
  root 'application#home'
	get 'css/:app', :to => redirect('/angularapp/css/%{app}.css')
	get 'js/:app', :to => redirect('/angularapp/js/%{app}.js')
	get 'images/favicon.ico', :to => redirect('/angularapp/images/favicon.ico')
	get 'images/:image_name.:ext', :to => redirect('/angularapp/images/%{image_name}.%{ext}')

	match '*any' => 'application#options', :via => [:options]
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
	#   s
  #   end
  get 'login', :to => 'sessions#new', :as => :login
  post 'api/resetpassword', to: 'sessions#reset_password'
  post 'api/changepassword', to: 'sessions#change_password'
  post 'api/changeusername', to: 'sessions#change_username'
  post 'api/signup', to: 'sessions#create'
  post 'api/login', to: 'sessions#login'
  get 'verify/', to: 'sessions#verify_email'
  get 'auth/:provider/callback', :to => 'sessions#create'
  get 'auth/failure', :to => redirect('/')
  get 'api/user', to: 'sessions#get';
  get 'api/user/logout', to: 'sessions#destroy';

	post 'api/filter_locations', to: 'locations#filter_locations'
	get 'api/filter_locations', to: 'locations#filter_locations'
	get 'api/location/:slug', to: 'locations#show', as: 'location'
	get 'api/filters', to: 'application#filters'
	post 'api/collect_locations_quotes', to:'locations#collect_locations_quotes'
	get 'api/collect_locations_quotes', to:'locations#collect_locations_quotes'
	post 'api/collect_locations_quotes', to:'locations#collect_locations_quotes'
	get 'api/get_attribute_options', to: 'application#get_attribute_options'
	post 'api/submit_new_location', to: 'locations#new_location'
	post 'api/locations/:id/accommodations', to: 'locations#edit_accommodations'
	post 'api/locations/:id/gettingin', to: 'locations#edit_getting_in'
	post 'api/locations/:id/foodoptions', to: 'locations#edit_food_options'
	post 'api/locations/:id/sections', to: 'locations#edit_sections'
	post 'api/locations/:id/email', to: 'locations#change_location_email'
	get 'api/location/name/all', to: 'locations#location_names'


	post 'api/infosection/:id', to: 'info_sections#update_info_section'
	post 'api/infosection/', to: 'info_sections#update_info_section'

	get 'api/accommodations/all', to: 'constant_data#get_all_accommodations'
	get 'api/foodoptions/all', to: 'constant_data#get_all_food_options'
	get 'api/transportations/all', to: 'constant_data#get_all_transportations'

	get "/*path" => redirect("/?goto=%{path}")
end
