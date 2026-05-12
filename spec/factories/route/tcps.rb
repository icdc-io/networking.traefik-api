FactoryBot.define do
  factory :route_tcp, class: "Route::Tcp" do
    cloud_gateway

    sequence(:name)   { |n| "TCP-Route-#{n}" }
    hostname          { "#{name.downcase}.computedev.zby.icdc.io" }
    target_port       { 3000 }
    tls_termination   { "passthrough" }
    owner             { "user@example.com" }
    path              { "/" }
    ip_version        { 4 }
    insecure          { "" }
  end
end
