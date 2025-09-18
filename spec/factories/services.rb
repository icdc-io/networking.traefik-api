rand(17_592_186_044_416..281_474_976_710_655).to_s(16)
FactoryBot.define do
  factory :service do
    name { "Clone##{rand(1000)}" }
    ext_id { "260000000#{rand(10_000..99_999)}" }
    ipaddresses do
      "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}" \
        ",#{rand(65_536).to_s(16)}::#{rand(65_536).to_s(16)}:#{rand(65_536).to_s(16)}:#{rand(65_536).to_s(16)}"
    end
    owner { "test_member@test.com" }
    account { "test" }
  end
end
