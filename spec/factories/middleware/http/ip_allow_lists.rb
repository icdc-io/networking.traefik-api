FactoryBot.define do
  factory :middleware_http_ip_allow_list,
          class: 'Middleware::Http::IpAllowList' do
    route factory: :route_http
    options { { "sourceRange" => "127.0.0.1/32,192.168.1.7" } }
  end
end
