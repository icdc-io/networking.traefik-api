Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      get 'cloudgw', to: 'gateways#index'
      get 'cloudgw/:id', to: 'gateways#show'
      post 'cloudgw', to: 'gateways#create'
      delete 'cloudgw/:id', to: 'gateways#delete'
    end
  end
end
