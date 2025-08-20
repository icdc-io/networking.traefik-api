FactoryBot.define do
  factory :route do
    cloud_gateway
    name              { "Route-#{rand(165_437_652).to_s(36)}" }
    hostname          { "#{name.downcase}.computedev.zby.icdc.io" }
    target_port       { rand(1000..60_000) }
    tls_termination   { "" }
    owner             { "test_member@test.com" }
    path              { "/" }
    source_proto      { "tcp" }
    destination_proto { "tcp" }
    ip_version        { 4 }
    insecure          { "" }
    labels            { rand(36..1295).to_s(36).upcase.to_s }

    # services
    # certificate
  end
end
