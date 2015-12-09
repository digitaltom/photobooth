Rails.application.routes.draw do

  root 'application#index'

  resources :picture_sets, only: [:index, :show, :create, :destroy]

end
