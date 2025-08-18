Rails.application.routes.draw do
  require "sidekiq/web"
  require "sidekiq/cron/web"

  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"
  mount Sidekiq::Web => "/sidekiq"

  get "/up", to: proc { [ 200, {}, [ "Up!" ] ] }

  namespace :api do
    namespace :v1 do
      # Old-style: remove after 2023
      get    "config/:cloudgw_id", to: "gateways#traefik_config"
      # end

      get    "gateways",              to: "gateways#index"
      post   "gateways",              to: "gateways#create_cloudgw"
      get    "gateways/:cloudgw_id/config", to: "gateways#traefik_config"
      get    "gateways/:id",          to: "gateways#show"
      put    "gateways/:id",          to: "gateways#update_cloudgw"
      delete "gateways/:id",          to: "gateways#delete_cloudgw"

      get    "certificates",          to: "certificates#index"
      get    "certificates/:id",      to: "certificates#show"
      get    "cert-download/:cloudgw_id", to: "certificates#download"
      post   "certificates",          to: "certificates#create"
      delete "certificates/:id",      to: "certificates#delete"
      put    "certificates/:id",      to: "certificates#update"

      get    "services",              to: "services#index"

      resources :routes
    end
  end
end
