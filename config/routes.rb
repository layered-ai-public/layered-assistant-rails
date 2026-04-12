Layered::Assistant::Engine.routes.draw do
  root "setup#index"

  l_managed_resources :personas
  l_managed_resources :skills

  resources :assistants, except: [:show] do
    resources :conversations, only: [:index]
  end
  resources :providers, only: [:index, :new, :create, :edit, :update, :destroy] do
    resources :models, only: [:index, :new, :create, :edit, :update, :destroy]
  end
  resources :conversations, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    patch :stop, on: :member
    resources :messages, only: [:index, :create, :destroy]
  end

  namespace :panel do
    resources :conversations, only: [:index, :show, :new, :create, :destroy] do
      patch :stop, on: :member
      resources :messages, only: [:create]
    end
  end

  namespace :public do
    resources :assistants, only: [:index, :show]
    resources :conversations, only: [:show, :create] do
      patch :stop, on: :member
      resources :messages, only: [:create]
    end

    namespace :panel do
      resources :conversations, only: [:index, :show, :new, :create] do
        patch :stop, on: :member
        resources :messages, only: [:create]
      end
    end
  end
end
