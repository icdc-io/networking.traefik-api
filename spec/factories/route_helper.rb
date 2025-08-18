def add_routes_services(route, services)
  name = RoutesService.generate_name

  if services.one?
    service = Service.find_by(id: services.first[:id])
    create_routes_service(route, service, :loadbalancer, nil, name)
  elsif services.many?
    services.map do |data|
      service = Service.find_by(id: data[:id])
      create_routes_service(route, service, :weighted, data[:weight], name)
    end
  end
end

def create_routes_service(route, service, balance_type, value, name)
  RoutesService.create!(
    route:,
    service:,
    balance_type:,
    value:,
    name:         RoutesService.unique_name(name)
  )
end
