FactoryBot.define do
  factory :middleware_http, class: 'Middleware' do
    route
    type    { 'Middleware::Http::RateLimit' }
    options { nil }
  end
end
