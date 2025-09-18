FactoryBot.define do
  factory :service do
    sequence(:name)        { |n| "Service-#{n}" }
    sequence(:ext_id)      { |n| (10_000_000_000_000 + n).to_s }
    sequence(:ipaddresses) do |n|
      "#{[ 10, n / 65_536 % 256, n / 256 % 256, n % 256 ].join('.')}," \
        "10::#{str = n.to_s(16)
               str = ('0' * (4 - (str.length % 4))) + str.to_s
               str.scan(/..../).join(':')}"
    end
    owner   { "user@example.com" }
    account { "test" }
  end
end
