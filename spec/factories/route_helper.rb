def add_routes_services(route, services)
  if services.count == 1
  service = Service.find_by(:id => services.first[:id])
  RoutesService.create!(
    :route => route,
    :service => service,
    :balance_type => :loadbalancer,
    :value => nil,
    :name => "#{service.ext_id}-#{route.target_port}"
  )
  elsif services.count > 1
    services.map do |data|
    service = Service.find_by(:id => data[:id])
    RoutesService.create!(
      :route => route,
      :service => service,
      :balance_type => :weighted,
      :value => data[:weight],
      :name => RoutesService.generate_name
    )
    end
  end
end
