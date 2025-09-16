FactoryBot.define do
  factory :middleware_http_redirect_scheme,
          class: 'Middleware::Http::RedirectScheme' do
    route factory: :route_http
  end
end
