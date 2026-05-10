Layered::Assistant::Engine.routes.draw do
  root "setup#index"

  layered_resources :personas, except: [ :show ], namespace: "Layered::Assistant"
  layered_resources :skills, except: [ :show ], namespace: "Layered::Assistant"

  layered_resources :assistants, except: [ :show ],
    namespace: "Layered::Assistant",
    controller: "/layered/assistant/assistants"

  layered_resources :providers, except: [ :show ], namespace: "Layered::Assistant"
  resources :providers, only: [] do
    layered_resources :models, except: [ :show ], namespace: "Layered::Assistant"
  end

  layered_resources :conversations, except: [ :show ],
    namespace: "Layered::Assistant",
    controller: "/layered/assistant/conversations"

  resources :assistants, only: [] do
    layered_resources :conversations, only: [ :index ],
      namespace: "Layered::Assistant",
      controller: "/layered/assistant/conversations"
  end

  resources :conversations, only: [ :show ] do
    patch :stop, on: :member
  end

  resources :conversations, only: [] do
    layered_resources :messages, only: [ :index, :create, :destroy ],
      namespace: "Layered::Assistant",
      controller: "/layered/assistant/messages"
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
