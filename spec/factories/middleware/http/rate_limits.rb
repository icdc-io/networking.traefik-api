FactoryBot.define do
  factory :middleware_http_rate_limit, class: 'Middleware::Http::RateLimit' do
    route
  end
end
