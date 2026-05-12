FactoryBot.define do
  factory :middleware_http_replace_path_regex,
          class: 'Middleware::Http::ReplacePathRegex' do
    route factory: :route_http
    options { { "regex" => "^/foo/(.*)" } }
  end
end
