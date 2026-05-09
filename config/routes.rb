Layered::Assistant::Engine.routes.draw do
  root "setup#index"

  layered_resources :personas, except: [ :show ], namespace: "Layered::Assistant"
  layered_resources :skills, except: [ :show ], namespace: "Layered::Assistant"

  layered_resources :assistants, except: [ :show ],
    namespace: "Layered::Assistant",
    controller: "/layered/assistant/assistants"
  resources :assistants, only: [] do
    resources :conversations, only: [ :index ]
  end

  layered_resources :providers, except: [ :show ], namespace: "Layered::Assistant"
  resources :providers, only: [] do
    layered_resources :models, except: [ :show ], namespace: "Layered::Assistant"
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
