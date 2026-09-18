Rails.application.routes.draw do
  devise_for :users,
             path_names: { sign_in: "login", sign_out: "logout" },
             controllers: {
               sessions: "users/sessions",
               registrations: "users/registrations",
               passwords: "users/passwords"
             }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"
  
  resources :products, only: [:index, :show]
  resource :account, only: [:show, :update]
  resources :addresses, only: [:create, :update, :destroy]

  resources :orders, only: [:index, :show, :create] do
    member do
      patch :cancel
      post :pay
      get "payment/return", action: :payment_return, as: :payment_return
    end
  end
  resource :payment, only: [:new, :create]

  namespace :webhooks do
    post "mercado_pago", to: "mercado_pago#create"
  end

  resource :cart, only: :show do
    resources :items, controller: "cart_items", only: [:create, :update, :destroy]
  end

  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    root to: 'dashboard#index'
    resources :products do
      member do
        post :generate_ai_suggestions
        patch :approve_ai_description
        patch :approve_ai_image
      end
    end
    resources :categories
    resources :orders, only: [:index, :show] do
      member do
        patch :update_status
      end
    end
    resources :clients, only: [:index, :show]

    namespace :settings do
      root to: "store#show"
      resource :store, only: [:show, :update], controller: "store"
      resource :shipping, only: [:show, :update], controller: "shipping"
      resource :notifications, only: [:show, :update], controller: "notifications"
      resource :payments, only: [:show, :update], controller: "payments"
      resource :appearance, only: [:show, :update], controller: "appearance"
      resource :account, only: [:show, :update], controller: "account"
      resources :colors
      resources :storages
      resources :administrators
    end
  end
end
