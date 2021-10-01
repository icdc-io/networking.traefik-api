class CloudGateway < ApplicationRecord
  has_many :routes

  def config
    {
      "http" => {
        "routers" => routers_from_template,
        "services" => services_from_template
      }
    }.to_yaml.strip
  end

  private

  def routers_from_template
    routers = {}
    routes.map do |route|
      routers[route.name] = {
        "entryPoints" => ["web"],
        "service" => route.services.first.name,
        "rule" => "Path(`#{route.path}`)"
      }
    end
    routers
  end

  def services_from_template
    services = {}
    routes.map do |route|
      route.services.map do |service|
        services[service.name] = {
          "loadBalancer" => {
            "servers" => [
              {
                "url" => "http://#{service.ipaddresses.split(',')[0]}:#{route.target_port.to_i}"
              }
            ]
          }
        }
      end
      services
    end
  end

end
