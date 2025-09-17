FactoryBot.define do
  factory :middleware_http_strip_prefix_regex,
          class: 'Middleware::Http::StripPrefixRegex' do
    route factory: :route_http
    options { {} }
  end
end
