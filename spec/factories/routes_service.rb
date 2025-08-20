FactoryBot.define do
  factory :routes_service, aliases: %i[route_service] do
    route
    service
    name         { rand(39_284_024).to_s(36) }
    balance_type { :loadbalancer }
    value        { nil }
  end
end
