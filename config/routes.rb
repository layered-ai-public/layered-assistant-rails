Layered::Assistant::Engine.routes.draw do
  root "setup#index"
  layered_resources :personas, namespace: "Layered::Assistant", except: [ :show ]
  layered_resources :skills, namespace: "Layered::Assistant", except: [ :show ]
  resources :assistants, except: [ :show ] do
    resources :conversations, only: [ :index ]
  end
  layered_resources :providers, namespace: "Layered::Assistant", controller: "providers", except: [ :show ]
  resources :providers, only: [] do
    layered_resources :models, namespace: "Layered::Assistant", except: [ :show ]
  end
  resources :conversations, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    patch :stop, on: :member
    resources :messages, only: [ :index, :create, :destroy ]
  end

  namespace :panel do
    resources :conversations, only: [ :index, :show, :new, :create, :destroy ] do
      patch :stop, on: :member
      resources :messages, only: [ :create ]
    end
  end

  namespace :public do
    resources :assistants, only: [ :index, :show ]
    resources :conversations, only: [ :show, :create ] do
      patch :stop, on: :member
      resources :messages, only: [ :create ]
    end

    namespace :panel do
      resources :conversations, only: [ :index, :show, :new, :create ] do
        patch :stop, on: :member
        resources :messages, only: [ :create ]
      end
    end
  end
end
