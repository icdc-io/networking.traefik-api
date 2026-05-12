FactoryBot.define do
  factory :middleware_http_basic_auth, class: 'Middleware::Http::BasicAuth' do
    route factory: :route_http
    options { {} }
  end
end
