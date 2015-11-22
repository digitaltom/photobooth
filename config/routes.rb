Rails.application.routes.draw do

  root 'application#index'

  resources :pictures, only: [:create, :index, :show]

end
