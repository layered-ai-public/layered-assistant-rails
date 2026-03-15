Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount Layered::Assistant::Engine => "/layered/assistant"
  devise_for :users, path: "/", path_names: { sign_in: "login", sign_up: "register", sign_out: "logout" }
  root "pages#index"
end
