Rails.application.routes.draw do
  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"
  mount Sidekiq::Web => '/sidekiq'

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      get 'cloudgw', to: 'gateways#index'
      get 'config/:uuid', to: 'gateways#traefik_config'

      get 'certificates', to: 'certificates#index'
      get 'certificates/:id', to: 'certificates#show'
      get 'cert-download/:uuid', to: 'certificates#download'
      post 'certificates', to: 'certificates#create'
      delete 'certificates/:id', to: 'certificates#delete'

      get 'services', to: 'services#index'

      resources :routes 
    end
  end
end
