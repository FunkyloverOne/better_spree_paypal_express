# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  post '/paypal', to: 'paypal#express', as: :paypal_express
  get '/paypal/confirm', to: 'paypal#confirm', as: :confirm_paypal
  get '/paypal/cancel', to: 'paypal#cancel', as: :cancel_paypal
  get '/paypal/notify', to: 'paypal#notify', as: :notify_paypal

  namespace :admin do
    # Using :only here so it doesn't redraw those routes
    resources :orders, only: [] do
      resources :payments, only: [] do
        member do
          get 'paypal_refund'
          post 'paypal_refund'
        end
      end
    end
  end

  concern :api_base do
    resources :paypal_payments, only: [:create] do
      collection do
        post 'confirm'
        post 'cancel'
        get 'notify'
      end
    end
  end

  namespace :api do
    namespace :v2 do
      concerns :api_base
    end
  end
end
