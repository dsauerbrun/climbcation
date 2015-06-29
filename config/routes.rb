Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  #root 'application#index'
  root 'application#home'
	get 'js/app.js', :to => redirect('/angularapp/js/app.js')
	get 'css/app.css', :to => redirect('/angularapp/css/app.css')

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
	post 'api/filter_locations', to: 'locations#filter_locations'
	get 'api/filter_locations', to: 'locations#filter_locations'
	get 'api/location/:slug', to: 'locations#show', as: 'location'
	get 'api/filters', to: 'application#filters'
	post 'api/collect_locations_quotes', to:'locations#collect_locations_quotes'
	get 'api/collect_locations_quotes', to:'locations#collect_locations_quotes'
	post 'api/collect_locations_quotes', to:'locations#collect_locations_quotes'
	get 'api/get_attribute_options', to: 'application#get_attribute_options'
end
