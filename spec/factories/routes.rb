FactoryBot.define do
  factory :route do
    cloud_gateway
    sequence(:name)   { |n| "Route-#{n}" }
    hostname          { "#{name.downcase}.computedev.zby.icdc.io" }
    target_port       { 3000 }
    tls_termination   { "" }
    owner             { "user@example.com" }
    path              { "/" }
    ip_version        { 4 }
    insecure          { "" }
  end
end
