route_name = rand(17592186044416..281474976710655).to_s(16)
FactoryBot.define do
  factory :service do
    name { "Clone##{rand(1000)}" }
    ext_id { "260000000#{rand(10000..99999)}" }
    ipaddresses { "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}" + 
                  ",#{rand(65536).to_s(16)}::#{rand(65536).to_s(16)}:#{rand(65536).to_s(16)}:#{rand(65536).to_s(16)}" }
    owner { "test_member@test.com" }
    account { "test" }
  end
end
