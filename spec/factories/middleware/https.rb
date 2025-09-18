FactoryBot.define do
  factory :middleware_http, class: "Middleware::Http::AddPrefix" do
    route factory: :route_http
    type { "Middleware::Http::AddPrefix" }
    options { { "prefix" => "/foo" } }
  end
end
