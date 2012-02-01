ActionController::Routing::Routes.draw do |map|
  # Add your own custom routes here.
  # The priority is based upon order of creation: first created -> highest priority.

  map.connect '', :controller => 'products', :action => 'home'

  #-SEARCH do not remove this comment or edit the next line!
  map.connect 'search', :controller => 'products', :action => 'search'

  #-CONTACT do not remove this comment or edit the next line!
  map.connect 'contact-us', :controller => 'static_pages', :action => 'contact_us'

  map.connect 'forgotten-password', :controller => 'static_pages', :action => 'forgotten_password'
  map.connect 'change-password', :controller => 'static_pages', :action => 'change_password'
  map.connect 'captcha', :controller => 'static_pages', :action => 'captcha'

  #-PRODUCTS do not remove this comment or edit the next line!
  map.connect 'products/*categories', :controller => 'products', :action => 'category'

  #-OVERVIEW do not remove this comment or edit the next line!
  map.connect 'products-overview', :controller => 'products', :action => 'products_overview'

  map.connect 'product_images/thumbnail/:id/:width/:height', :controller => 'product_images', :action => 'thumbnail'
  map.connect 'product_images/thumbnail/:id/:width/:height.png', :controller => 'product_images', :action => 'thumbnail'
  # GRRRRR @ image_tag automatically appending '.png' when you have no extension...

  map.connect 'product_images/crop_thumbnail/:id', :controller => 'product_images', :action => 'cropped_thumb'
  map.connect 'product_images/crop_thumbnail/:id.png', :controller => 'product_images', :action => 'cropped_thumb'
  map.connect 'product_images/crop_thumbnail/:id/:option_value', :controller => 'product_images', :action => 'cropped_thumb'
  map.connect 'product_images/crop_thumbnail/:id/:option_value.png', :controller => 'product_images', :action => 'cropped_thumb'

  map.connect 'wholesale/retail-order-form', :controller => 'wholesale', :action => 'retail_order_form'
  map.connect 'wholesale/wholesale-order-form', :controller => 'wholesale', :action => 'wholesale_order_form'

  map.connect 'admin/features/:action/:id', :controller => 'admin/features', :action => 'list', :id => nil
  map.connect 'admin/categories/:action/:id', :controller => 'admin/categories', :action => 'list', :id => nil
  map.connect 'admin/static_pages/:action/:id', :controller => 'admin/static_pages', :action => 'list', :id => nil
  map.connect 'admin/newsletter_signups/:action/:id', :controller => 'admin/newsletter_signups', :action => 'list', :id => nil
  map.connect 'admin/options/:action/:id', :controller => 'admin/options', :action => 'list', :id => nil
  map.connect 'admin/orders/:action/:id', :controller => 'admin/orders', :action => 'list', :id => nil
  map.connect 'admin/reports/:action/:id', :controller => 'admin/reports', :action => 'list', :id => nil
  map.connect 'admin/settings/:action/:id', :controller => 'admin/settings', :action => 'edit', :id => nil
  map.connect 'admin/currencies/:action/:id', :controller => 'admin/currencies', :action => 'list', :id => nil
  map.connect 'admin/payment_gateways/:action/:id', :controller => 'admin/payment_gateways', :action => 'list', :id => nil
  map.connect 'admin/shipping_zones/:action/:id', :controller => 'admin/shipping_zones', :action => 'list', :id => nil
  map.connect 'admin/product_types/:action/:id', :controller => 'admin/product_types', :action => 'list', :id => nil
  map.connect 'admin/reviews/:action/:id', :controller => 'admin/reviews', :action => 'list', :id => nil
  map.connect 'admin/users/:action/:id', :controller => 'admin/users', :action => 'customers', :id => nil
  map.connect 'admin/barcodes/:action', :controller => 'admin/barcodes', :action => 'list'
  map.connect 'admin/credit_account/:action', :controller => 'admin/credit_account', :action => 'list'

  # Install the default route as low priority.
  map.connect ':controller/:action/:id'

  # Static pages clean up the rest (with user-definable URL's)
  map.connect '*anything', :controller => 'static_pages'
end
