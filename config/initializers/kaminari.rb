#hack to make will_paginate gem work with rails_admin
Kaminari.configure do |config|
	config.page_method_name = :per_page_kaminari
end
