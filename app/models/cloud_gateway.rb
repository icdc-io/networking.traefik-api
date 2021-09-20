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
    routes.collect(&:services).flatten.map do |service|
      services[service.name] = {
        "loadBalancer" => {
          "servers" => [
            {
              "url" => service.url
            }
          ]
        }
      }
      services
    end
  end

end
