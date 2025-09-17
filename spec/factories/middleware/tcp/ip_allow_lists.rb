FactoryBot.define do
  factory :middleware_tcp_ip_allow_list,
          class: 'Middleware::Tcp::IpAllowList' do
    route factory: :route_tcp
    options { { "sourceRange" => "127.0.0.1/32,192.168.1.7" } }
  end
end
