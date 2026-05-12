FactoryBot.define do
  factory :middleware, class: "Middleware::Http::RedirectScheme" do
    route factory: :route_http
    type { "Middleware::Http::RedirectScheme" }
    options { { "scheme" => "https" } }
  end
end
