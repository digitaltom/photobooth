Rails.application.routes.draw do

  root 'picture_sets#index'

  # angular routes
  get '/picture_sets/list', to: 'picture_sets#list'
  post '/picture_sets', to: 'picture_sets#create'
  delete '/picture_sets/:id', to: 'picture_sets#destroy'

  resources :picture_sets, only: [:index, :show]

end
