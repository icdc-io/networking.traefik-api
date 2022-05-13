class CloudGateway < ApplicationRecord
  has_many :routes, dependent: :destroy
  validates :cloudgw_id, uniqueness: true

  before_destroy { Certificate.select{|cert| (cert.cert_path.split('/')[-3] == cloudgw_id) if cert.cert_path}.each &:destroy! } 

  def config
    generated_config = {
      "http" => {
        "routers" => http(routes.where(:tls_termination => ["re-encrypt", "edge", nil])),
        "services" => services_section(routes.where(:tls_termination => ["re-encrypt", "edge", nil]), "http"),
      },
      "tcp" => {
        "routers" => tcp(routes.where(:tls_termination => ["passthrough"])),
        "services" => services_section(routes.where(:tls_termination => ["passthrough"]), "tcp")
      },
      "tls" => tls
    }
    generated_config["http"].merge!("middlewares" => middlewares_redirects(routes.where(:insecure => "redirect"))) unless routes.where(:insecure => "redirect").empty?
    generated_config.delete("http") if routes.where(:tls_termination => ["re-encrypt", "edge", nil]).empty?
    generated_config.delete("tcp") if routes.where(:tls_termination => ["passthrough"]).empty?
    generated_config.to_yaml.strip
  end

  private

  def middlewares_redirects(routes)
    routes.map do |route|
      {
        "#{route.hostname}-redirect" => {
          "redirectScheme" => {
            "scheme" => "https",
            "permanent" => true
          }
        }
      }
    end.reduce({}, :merge)
  end

  def entrypoints =  { "entryPoints" => ["web", "websecure"] }

  def entrypoint_web(routers)
    routers.map do |key, value|
      value.delete("tls")
      { "#{key}-http" => value.merge("entryPoints" => ["web"]) }
    end
  end

  def entrypoint_websecure(routers)
    routers.map do |key, value|
      value.delete("middlewares")
      { "#{key}-https" => value.merge("entryPoints" => ["websecure"]) }
    end
  end

  def tls
    {
    "certificates" => Certificate.where("cert_path LIKE?", "%#{cloudgw_id}%").map do |certificate|
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
      "Host(`#{route.hostname}`) && PathPrefix(`#{route.path}`)"
    end
  end

  def http(filtered_routes)
    routers = {}
    middlewares = {}
    filtered_routes.map do |route|
      routers[route.hostname] = {
        "service" => route.routes_services[0].name,
        "rule" => rule(route)
      }

      if route.tls_termination == "re-encrypt"
        if route.certificate
          routers[route.hostname]["tls"] = {}
        else
          routers[route.hostname]["tls"] = {"certResolver" => "default" }
        end
      end

      if route.insecure == "redirect"
        routers[route.hostname].merge!({"middlewares" => ["#{route.hostname}-redirect"]})
      end
    end
    websecure = entrypoint_websecure(routers.deep_dup)
    web = entrypoint_web(routers.deep_dup)
    http_block = {}

    web.each {|x| http_block.merge!(x)}
    websecure.each {|x| http_block.merge!(x)}

    http_block 
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
          services[route_service.name] = {
            "weighted" => {
              "services" => weighted(RoutesService.where(:route_id => route.id), section, route)
            }
          }
          RoutesService.where(:route_id => route.id).collect(&:service).each do |service|
            services[service.name] = {
              "loadBalancer" => {
                "servers" => lb_server(service, section, route)
              }
            }
          end
        end
      end
    end.flatten
    services
  end

  def lb_server(service, section, route)
    ip_version = route.ip_version || 4
    case section
    when "http"
      service.addresses(ip_version).split(',').map do |ip|
        if route.target_port
          {"url" => "#{schema(route)}://#{ip}:#{route.target_port.to_i}"}
        else
          {"url" => "#{schema(route)}://#{ip}"}
        end
      end
    when "tcp"
      service.addresses(ip_version).split(',').map do |ip|
        if route.target_port
          {"address" => "#{ip}:#{route.target_port.to_i}"}
        else
          {"address" => "#{ip}"}
        end
      end
    end
  end

  def weighted(route_services, section, route)
    route_services.map do |route_service|
      {
        "name" => route_service.service.name, 
        "weight" => route_service.value
      }
    end
  end

  def schema(route)
    return "https" if route.tls_termination == "re-encrypt"
    "http"
  end

end
