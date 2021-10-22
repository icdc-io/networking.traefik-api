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
      puts route.id
      routers[route.name] = {
        "entryPoints" => [
          "web" => {
            "service" => route.routes_services[0].name,
            "rule" => "Path(`#{route.path}`)",
            "tls" => [{
              "certFile" => route.certificate.cert_path,
              "keyFile" => route.certificate.key_path
            }]
          }
        ]}
    end
    puts routers
    routers
  end

  def services_from_template
    services = {}
    routes.map do |route|
      route.routes_services.map do |rs|
        if rs.balance_type == "loadbalancer"
          services[rs.service.name] = {"loadBalancer" => {
            "servers" =>
              rs.service.ipaddresses.split(',').map do |ip|
                {"url" => "#{ip}:#{route.target_port.to_i}"}
              end
          }
        }
        else
          services[rs.name] = {"weighted" => {
            "services" => 
              RoutesService.where(:route_id => route.id).map do |route_service|
                services[route_service.service.name] = {
                  "loadBalancer" => {
                    "servers" =>
                      route_service.service.ipaddresses.split(',').map do |ip|
                        {"url" => "#{ip}:#{route.target_port.to_i}"}
                      end
                  }
                }
                {
                  "name" => route_service.service.name, 
                  "weight" => route_service.value
                }
              end
          }
        }
        end
      end
    end
    services
  end


end
