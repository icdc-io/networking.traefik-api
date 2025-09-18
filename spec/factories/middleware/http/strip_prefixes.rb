FactoryBot.define do
  factory :middleware_http_strip_prefix,
          class: 'Middleware::Http::StripPrefix' do
    route factory: :route_http
    options { {} }
  end
end
