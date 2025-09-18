FactoryBot.define do
  factory :middleware_http_add_prefix, class: 'Middleware::Http::AddPrefix' do
    route factory: :route_http
    options { { "prefix" => "/foo" } }
  end
end
