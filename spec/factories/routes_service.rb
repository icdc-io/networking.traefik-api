FactoryBot.define do
  factory :routes_service do
    name {rand(39284024).to_s(36)}
    balance_type {:loadbalancer}
    value {nil}
    #route
    #service
  end
end
