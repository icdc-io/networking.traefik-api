FactoryBot.define do
  factory :middleware_tcp, class: "Middleware::Tcp::IpAllowList" do
    route factory: :route_tcp
    type { "Middleware::Tcp::IpAllowList" }
    options { { "sourceRange" => "127.0.0.1/32,192.168.1.7" } }
  end
end
