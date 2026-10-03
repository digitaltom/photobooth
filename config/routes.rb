# frozen_string_literal: true

Rails.application.routes.draw do

  root 'sets#index'
  post 'picture_sets' => 'sets#create'

  resources :sets, only: %i[show] do
    member do
      get :slideshow
      get 'files/:name', action: :file, as: :file, constraints: { name: %r{[^/]+} }
    end
  end

  get 'admin' => 'admin#show'
  scope 'admin', controller: :admin, as: :admin do
    get 'login', action: :login_form
    post 'login'
    delete 'logout'
    patch 'password'
    patch 'time'
    patch 'caption'
    get 'wifi_sign'
    post 'power'
    post 'galleries', action: :create_gallery
    patch 'galleries/:id/activate', action: :activate_gallery, as: :activate_gallery
  end

  # Captive portal: phone connectivity checks (/generate_204, /hotspot-detect.html) land here and open the gallery
  get '*path', to: redirect('/'), format: false
end
