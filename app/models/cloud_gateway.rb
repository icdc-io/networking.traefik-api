class CloudGateway < ApplicationRecord
  has_many :routes

  def config
    generated_config = {
      "http" => {
        "routers" => http(routes.where(:tls_termination => ["re-encrypt", "edge"])),
        "services" => services_section(routes.where(:tls_termination => ["re-encrypt", "edge"]), "http")
      },
      "tcp" => {
        "routers" => tcp(routes.where(:tls_termination => ["passthrough"])),
        "services" => services_section(routes.where(:tls_termination => ["passthrough"]), "tcp")
      },
      "tls" => tls
    }
    generated_config.delete("http") if routes.where(:tls_termination => ["re-encrypt", "edge"]).empty?
    generated_config.delete("tcp") if routes.where(:tls_termination => ["passthrough"]).empty?
    generated_config.to_yaml.strip
  end

  private

  def entrypoints =  { "entryPoints" => ["web", "websecure"] }
  
  def tls
    {
    "certificates" => Certificate.all.map do |certificate|
        {
        "certFile" => "#{ENV['TRAEFIK_PATH']}/#{certificate.cert_path}",
        "keyFile" => "#{ENV['TRAEFIK_PATH']}/#{certificate.key_path}"
        }
      end
    }
  end

  def rule(route)
    if route.path == "/"
      "Host(`#{route.hostname}`)"
    else
      "PathPrefix(`#{route.path}`)"
    end
  end

  def http(filtered_routes)
    routers = {}
    filtered_routes.map do |route|
      routers[route.hostname] = {
        "service" => route.routes_services[0].name,
        "rule" => rule(route)
      }
      routers[route.hostname].merge!(entrypoints)
      routers[route.hostname]["tls"] = {} if route.insecure == "none"
    end
    routers
  end

  def tcp(filtered_routes)
    routers = {}
    filtered_routes.map do |route|
      routers[route.name] = {
        "service" => route.routes_services[0].name,
        "rule" => "HostSNI(`#{route.hostname}`)",
        "tls" => {
          "passthrough" => true
        }
      }
      routers[route.name].merge!(entrypoints)
    end
    routers
  end

  def services_section(selected_routes, section)
    services = {}
    selected_routes.map do |route|
      route.routes_services.map do |route_service|
        if route_service.balance_type == "loadbalancer"
          services[route_service.service.name] = {
            "loadBalancer" => {
              "servers" =>  lb_server(route_service.service, section, route)
            }
          }
        else
          service[route_service.name] = {
            "weighted" => {
              "services" => weighted(RoutesService.where(:route_id => route.id), section, route)
            }
          }
        end
      end
    end.flatten
  end

  def lb_server(service, section, route)
    case section
    when "http"
      service.ipaddresses.split(',').map do |ip|
        {"url" => "#{schema(route)}://#{ip}:#{route.target_port.to_i}"}
      end
    when "tcp"
      service.ipaddresses.split(',').map do |ip|
        {"address" => "#{ip}:#{route.target_port.to_i}"}
      end
    end
  end

  def weighted(route_services, section, route)
    route_services.map do |route_service|
      {
        "name" => route_service.service.name, 
        "weight" => route_service.value
      }.merge!(lb_server(route_service, section, route))
    end
  end

  def schema(route)
    return "https" if route.insecure == "none"
    "https"
  end

end
