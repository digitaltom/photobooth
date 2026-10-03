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

  # Captive portal: phone connectivity checks (/generate_204, /hotspot-detect.html) land here and open the gallery
  get '*path', to: redirect('/'), format: false
end
