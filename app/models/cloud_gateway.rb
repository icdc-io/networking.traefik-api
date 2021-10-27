class CloudGateway < ApplicationRecord
  has_many :routes

  def config
    generated_config = {
      "http" => {
        "routers" => http_section(routes.where(:tls_termination => ["re-encrypt", "edge"])),
        "services" => services_section(routes.where(:tls_termination => ["re-encrypt", "edge"]), "http")
      },
      "tcp" => {
        "routers" => tcp_section(routes.where(:tls_termination => ["passthrough"])),
        "services" => services_section(routes.where(:tls_termination => ["passthrough"]), "tcp")
      },
      #"udp" => {},
      "tls" => tls_section
    }
    generated_config.delete("http") if routes.where(:tls_termination => ["re-encrypt", "edge"]).empty?
    generated_config.delete("tcp") if routes.where(:tls_termination => ["passthrough"]).empty?
    generated_config.to_yaml.strip
  end

  private

  def tls_section
    {
    "certificates" => Certificate.all.map do |certificate|
        {
        "certFile" => certificate.cert_path,
        "keyFile" => certificate.key_path
        }
      end
    }
  end

  def generate_rule(route)
    if route.path == "/"
      "Host(`#{route.hostname}`)"
    else
      "PathPrefix(`#{route.path}`)"
    end
  end

  def http_section(filtered_routes)
    routers = {}
    filtered_routes.map do |route|
      routers[route.hostname] = {
        "entryPoints" => [
          "web"
         ],
        "service" => route.routes_services[0].name,
        "rule" => generate_rule(route)
      }
      routers[route.hostname]["tls"] = {} if route.insecure == "none"
    end
    routers
  end

  def tcp_section(filtered_routes)
    routers = {}
    filtered_routes.map do |route|
      routers[route.name] = {
        "entryPoints" => [
          "web",
          "websecure"
         ],
        "service" => route.routes_services[0].name,
        "rule" => "HostSNI(`#{route.hostname}`)",
        "tls" => {
          "passthrough" => true
        }
      }
    end
    routers
  end

  def services_section(filtered_routes, trafik_type)
    services = {}
    filtered_routes.map do |route|
      route.routes_services.map do |rs|
        if rs.balance_type == "loadbalancer"
          services[rs.service.name] = {"loadBalancer" => {
            "servers" =>
              rs.service.ipaddresses.split(',').map do |ip|
                if trafik_type == "http"
                  {"url" => "http://#{ip}:#{route.target_port.to_i}#{route.path}"}
                else
                  {"address" => "#{ip}:#{route.target_port.to_i}#{route.path}"}
                end
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
                        if trafik_type == "http"
                          {"url" => "http://#{ip}:#{route.target_port.to_i}#{route.path}"}
                        else
                          {"address" => "#{ip}:#{route.target_port.to_i}#{route.path}"}
                        end
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
