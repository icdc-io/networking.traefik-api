FactoryBot.define do
  factory :cloud_gateway do
    name { 'vpn-' + rand(1..99).to_s}
    account {'test'}
    cloudgw_id {rand(4096..65535).to_s(16) + rand(4096..65535).to_s(16) + '-' + rand(4096..65535).to_s(16) + '-' + rand(1000..9999).to_s + '-' + rand(4096..65535).to_s(16) + '-' + rand(17592186044416..281474976710655).to_s(16)}
  end
end
