Rails.application.routes.draw do

  root 'application#index'

  resources :picture_sets, only: %i[index show create destroy] do
    scope module: :picture_sets do
      resources :emails, only: :create
    end
  end
end
