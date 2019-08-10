# frozen_string_literal: true

Rails.application.routes.draw do

  root 'application#index'

  resources :picture_sets, only: %i[index show create destroy], defaults: { format: 'json' } do
    scope module: :picture_sets do
      resources :emails, only: :create, defaults: { format: 'json' }
    end
  end
end
