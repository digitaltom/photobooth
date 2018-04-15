Rails.application.routes.draw do

  root 'application#index'

  resources :picture_sets, only: %i[index show create destroy]

end
