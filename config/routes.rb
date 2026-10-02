# frozen_string_literal: true

Rails.application.routes.draw do

  root 'picture_sets#index'

  resources :picture_sets, only: %i[index show create destroy] do
    member do
      get :gallery
      get :slideshow
    end
    scope module: :picture_sets do
      resources :emails, only: %i[new create]
    end
  end
end
