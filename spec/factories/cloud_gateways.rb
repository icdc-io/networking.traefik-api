FactoryBot.define do
  factory :cloud_gateway do
    name { "vpn-#{rand(1..99)}" }
    account { 'test' }
    cloudgw_id do
      "#{rand(4096..65_535).to_s(16)}#{rand(4096..65_535).to_s(16)}-#{rand(4096..65_535).to_s(16)}-#{rand(1000..9999)}-#{rand(4096..65_535).to_s(16)}-#{rand(17_592_186_044_416..281_474_976_710_655).to_s(16)}"
    end
  end
end
