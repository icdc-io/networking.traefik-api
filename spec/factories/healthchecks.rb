FactoryBot.define do
  factory :healthcheck do
    route
    path             { "" }
    scheme           { "http" }
    port             { 3000 }
    interval         { 15 }
    timeout          { 3 }
    hostname         { "example.com" }
    headers          do
      { "X-Platform-Account" => "test",
        "X-Platform-Role"    => "admin" }
    end
    follow_redirects { false }
    add_attribute(:method) { "HEAD" }
  end
end
