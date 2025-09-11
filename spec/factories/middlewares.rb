FactoryBot.define do
  factory :middleware do
    route
    type { "Middleware::Http::RedirectScheme" }
    options { { scheme: "https" } }
  end
end
