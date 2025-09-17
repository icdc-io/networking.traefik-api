FactoryBot.define do
  factory :middleware_http_headers, class: 'Middleware::Http::Headers' do
    route factory: :route_http
    options { {} }
  end
end
