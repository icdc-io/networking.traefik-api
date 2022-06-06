route_name = "Route-" + rand(165437652).to_s(36)
FactoryBot.define do
  factory :route do
    name {rand(165437652).to_s(36)}
    hostname {"#{route_name.downcase}.computedev.zby.icdc.io"}
    target_port {rand(1000..60000)}
    tls_termination {"passthrough"}
    owner {"test_member@test.com"}
    path {"/"}
    source_proto {"tcp"}
    destination_proto {"tcp"}
    ip_version {4}
    insecure {"None"}
    labels {"#{rand(36..1295).to_s(36).upcase}"}
    #cloud_gateway_id
    #services
    #certificate_id
  end
end
