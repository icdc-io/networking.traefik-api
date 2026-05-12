FactoryBot.define do
  factory :middleware_http_replace_path,
          class: 'Middleware::Http::ReplacePath' do
    route factory: :route_http
    options { { "path" => "/foo" } }
  end
end
