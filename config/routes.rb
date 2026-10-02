# frozen_string_literal: true

Rails.application.routes.draw do

  root 'sets#index'
  get 'kiosk' => 'kiosk#show'
  post 'picture_sets' => 'sets#create'

  resources :sets, only: %i[show] do
    member do
      get :slideshow
      get 'files/:name', action: :file, as: :file, constraints: { name: %r{[^/]+} }
    end
  end
end
