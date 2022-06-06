class CloudGateway < ApplicationRecord
  attribute :cloudgw_instance, :string
  has_many :routes, dependent: :destroy
  validates :cloudgw_id, uniqueness: true

  before_destroy { Certificate.select{|cert| (cert.cert_path.split('/')[-3] == cloudgw_id) if cert.cert_path}.each &:destroy! }
  after_destroy { Dir.delete("certificates/#{cloudgw_id}") if File.exist?("certificates/#{cloudgw_id}") }

  def config
    generated_config = {}
    generated_config["http"] = http if routes.find_by(:tls_termination => ["re-encrypt", "edge", nil]) || 
                                       routes.find_by(:tls_termination => "passthrough", :insecure => "redirect")
    generated_config["tcp"] = tcp if routes.find_by(:tls_termination => "passthrough")
    if routes.where.not(:tls_termination => nil).find_by(:insecure => "redirect")
      generated_config["http"]["middlewares"] = middlewares
    end
    generated_config["tls"] = tls if Certificate.find{|cert| (cert.cert_path.split('/')[-3] == cloudgw_id) if cert.cert_path}
    generated_config.to_yaml.strip
  end

  def cloudgw_instance
    "cloudgw-#{cloudgw_id.split('-').first}"
  end

  private

  def http
    http_block = { "routers" => {}, "services" => {} }

    routes.where(:tls_termination => ["re-encrypt", "edge", nil]).each do |route|
      http_block["routers"].merge! routers_http(route)
      http_block["services"].merge! services_section(route, :http)
    end

    routes.where(:tls_termination => "passthrough", :insecure => "redirect").each do |route|
      http_block["routers"].merge! routers_http(route)
      http_block["services"].merge! services_section(route, :http)
    end

    http_block
  end

<<<<<<< HEAD
  def tls
    {
    "certificates" => Certificate.where("cert_path LIKE?", "%#{cloudgw_id}%").map do |certificate|
        {
        "certFile" => "#{ENV['TRAEFIK_CERT_PATH']}/#{certificate.cert_path}",
        "keyFile" => "#{ENV['TRAEFIK_CERT_PATH']}/#{certificate.key_path}"
        }
      end
=======
  def routers_http(route)
    router = {
      "service" => route.routes_services[0].name,
      "rule" => rule(route),
      "tls" => route.certificate ? true : { "certResolver" => "default" }
>>>>>>> master
    }
    if route.insecure == "redirect" && route.tls_termination
      router.merge!(
        { "middlewares" => [ "#{route.name}-redirect" ] }
      )
    end

    outp = { "#{route.name}-http" => router.except("tls").merge("entryPoints" => ["web"]) }
    if route.tls_termination.in? ["re-encrypt", "edge"]
      outp.merge!( "#{route.name}-https" => router.except("middlewares").merge("entryPoints" => ["websecure"]) )
    end
    outp
  end

  def rule(route)
    route.path == "/" ? "Host(`#{route.hostname}`)" : "Host(`#{route.hostname}`) && PathPrefix(`#{route.path}`)"
  end

<<<<<<< HEAD
  def http(filtered_routes)
    routers = {}
    middlewares = {}
    filtered_routes.map do |route|
      routers[route.hostname] = {
        "service" => route.routes_services[0].name,
        "rule" => rule(route)
      }

      if route.certificate
        routers[route.hostname]["tls"] = true
      else
        routers[route.hostname]["tls"] = { "certResolver" => "default" }
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
=======
  def tcp
    tcp_block = { "routers" => {}, "services" => {} }
  
    routes.where(:tls_termination => ["passthrough"]).each do |route|
      tcp_block["routers"][route.name] = {
>>>>>>> master
        "service" => route.routes_services[0].name,
        "rule" => "HostSNI(`#{route.hostname}`)",
        "tls" => {
          "passthrough" => true
        }
      }
      tcp_block["services"].merge! services_section(route, :tcp)
    end

    tcp_block
  end

  def services_section(route, section)
    services = {}
    route_service = route.routes_services.first
    if route_service.balance_type == "loadbalancer"
      services[route_service.name] = {
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
        services["#{service.ext_id}-#{route.target_port}"] = {
          "loadBalancer" => {
            "servers" => lb_server(service, section, route)
          }
        }
      end
    end
    services
  end

  def lb_server(service, section, route)
    ip_version = route.ip_version || 4
    case section
    when :http
      service.addresses(ip_version).split(',').map do |ip|
        if route.target_port
          {"url" => "#{schema(route)}://#{ip}:#{route.target_port.to_i}"}
        else
          {"url" => "#{schema(route)}://#{ip}"}
        end
      end
    when :tcp
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
        "name" => "#{route_service.service.ext_id}-#{route.target_port}",
        "weight" => route_service.value
      }
    end
  end

  def schema(route)
    return "https" if route.tls_termination == "re-encrypt"
    "http"
  end

  def middlewares
    block = {}
    routes.where(:insecure => "redirect").each do |route|
      if route.tls_termination
        block["#{route.name}-redirect"] = {
          "redirectScheme" => {
              "scheme" => "https",
              "permanent" => true
            }
        }
      end
    end
    block
  end

  def tls
    {
      "certificates" => Certificate.select{|cert| (cert.cert_path.split('/')[-3] == cloudgw_id) if cert.cert_path}
        .map do |certificate|
          {
            "certFile" => "#{ENV['TRAEFIK_CERT_PATH']}/#{certificate.cert_path}",
            "keyFile" => "#{ENV['TRAEFIK_CERT_PATH']}/#{certificate.key_path}"
          }
        end
    }
  end
end
