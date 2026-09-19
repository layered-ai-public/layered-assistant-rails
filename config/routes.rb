Layered::Assistant::Engine.routes.draw do
  root "setup#index"
  layered_resources :personas, namespace: "Layered::Assistant", except: [ :show ]
  layered_resources :skills, namespace: "Layered::Assistant", except: [ :show ]
  layered_resources :assistants, namespace: "Layered::Assistant", controller: "assistants", except: [ :show ]
  resources :assistants, only: [] do
    resources :conversations, only: [ :index ]
  end
  layered_resources :providers, namespace: "Layered::Assistant", controller: "providers", except: [ :show ]
  resources :providers, only: [] do
    layered_resources :models, namespace: "Layered::Assistant", except: [ :show ]
  end
  resources :conversations, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    patch :stop, on: :member
    resources :messages, only: [ :index, :create, :destroy ]
    # Approving a tool call is the same act wherever it is rendered, and the
    # partial carrying the buttons is broadcast rather than requested, so it
    # cannot know which namespace it landed in. One route serves them all.
    # Public conversations are not among them: a tool that asks for consent
    # is withheld from a conversation with nobody to ask.
    resources :tool_calls, only: [ :update ]
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
