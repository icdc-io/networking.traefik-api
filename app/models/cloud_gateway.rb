class CloudGateway < ApplicationRecord
  attribute :cloudgw_instance, :string
  has_many :routes, dependent: :destroy
  validates :cloudgw_id, uniqueness: true

  after_destroy do
    FileUtils.rm_f(
      File.join(
        ENV.fetch("USERS_CERT_PATH_ARCH", "certificates/download"),
        "#{cloudgw_id}.zip"
      )
    )
  end

  # TODO: Move this to Config class
  def config
    generated_config = {}
    generated_config["http"] = http
    if routes.where(tls_termination: "passthrough").any?
      generated_config["tcp"] = tcp
    end
    if routes.where(insecure: "redirect").where.not(tls_termination: nil).any?
      generated_config["http"]["middlewares"] = middlewares
    end
    generated_config["tls"] = tls if Certificate.where(account:).any?
    generated_config.delete_if { |_key, value| value.empty? }.to_yaml.strip
  end

  def cloudgw_instance
    "cloudgw-#{cloudgw_id.split('-').first}"
  end

  private

  def http
    http_block = { "routers" => internal_ping_router, "services" => {} }

    routes
      .where(tls_termination: [ "re-encrypt", "edge", nil ])
      .or(routes.where(tls_termination: "passthrough", insecure: "redirect"))
      .find_each do |route|
      next if route.services.empty?

      http_block["routers"].merge! routers_http(route)
      http_block["services"].merge! services_section(route, :http)
    end

    http_block.delete_if { |_key, value| value.empty? }
  end

  def routers_http(route)
    router = {
      "service" => service_name(route),
      "rule"    => rule(route),
      "tls"     => route.certificate ? true : { "certResolver" => "default" }
    }

    if route.insecure == "redirect" && route.tls_termination
      router["middlewares"] = [ "#{route.name}-redirect" ]
    end

    outp = { "#{route.name}-http" => router.except("tls")
                                           .merge("entryPoints" => [ "web" ]) }

    if route.tls_termination.in? %w[re-encrypt edge]
      outp["#{route.name}-https"] =
        router.except("middlewares").merge("entryPoints" => [ "websecure" ])
    end

    outp
  end

  def rule(route)
    if route.path == "/"
      "Host(`#{route.hostname}`)"
    else
      "Host(`#{route.hostname}`) && PathPrefix(`#{route.path}`)"
    end
  end

  def tcp
    tcp_block = { "routers" => {}, "services" => {} }

    routes.where(tls_termination: [ "passthrough" ]).find_each do |route|
      next if route.services.empty?

      tcp_block["routers"][route.name] = {
        "service" => service_name(route),
        "rule"    => "HostSNI(`#{route.hostname}`)",
        "tls"     => { "passthrough" => true }
      }
      tcp_block["services"].merge!(services_section(route, :tcp))
    end

    tcp_block.delete_if { |_key, value| value.empty? }
  end

  def services_section(route, section)
    services = {}
    route_service = route.routes_services.first

    if route_service.balance_type == "loadbalancer"
      services[route_service.name] = {
        "loadBalancer" => {
          "servers" => lb_server(route_service.service, section, route)
        }
      }
    else
      services[route_service.group_name] = {
        "weighted" => {
          "services" => weighted(route.routes_services)
        }
      }
      route.routes_services.each do |routes_service|
        services[routes_service.name.to_s] = {
          "loadBalancer" => {
            "servers" => lb_server(routes_service.service, section, route)
          }
        }
      end
    end

    services.delete_if { |_key, value| value.empty? }

    if route.healthcheck_enabled
      healthcheck_section(services, route.healthcheck)
    end

    services
  end

  def healthcheck_section(lb_config, healthcheck)
    healthcheck =
      healthcheck.attributes
                 .except("id", "route_id", "created_at", "updated_at")
                 .compact

    healthcheck["interval"] += "s" if healthcheck["interval"]
    healthcheck["timeout"]  += "s" if healthcheck["timeout"]

    healthcheck["followRedirects"] = healthcheck.delete("follow_redirects")

    healthcheck = healthcheck.compact.delete_if { |_, v| [ "", {} ].include? v }

    lb_config.each_value do |lb|
      if lb["loadBalancer"]
        lb["loadBalancer"]["healthCheck"] = healthcheck
      elsif lb["weighted"]
        lb["weighted"]["healthCheck"] = {}
      end
    end
  end

  def lb_server(service, section, route)
    ip_version = route.ip_version || 4
    case section
    when :http
      schema = schema(route)
      service.addresses(ip_version).split(",").map do |ip|
        {
          "url" => if route.target_port
                     "#{schema}://#{ip}:#{route.target_port.to_i}"
                   else
                     "#{schema}://#{ip}"
                   end
        }
      end
    when :tcp
      service.addresses(ip_version).split(",").map do |ip|
        {
          "address" => if route.target_port
                         "#{ip}:#{route.target_port.to_i}"
                       else
                         ip.to_s
                       end
        }
      end
    end
  end

  def weighted(route_services)
    route_services.map do |route_service|
      {
        "name"   => route_service.name,
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
    redirect_scheme = {
      "redirectScheme" => {
        "scheme"    => "https",
        "permanent" => true
      }
    }
    routes.where(insecure: "redirect").find_each do |route|
      next if route.services.empty? || !route.tls_termination

      block["#{route.name}-redirect"] = redirect_scheme
    end
    block.delete_if { |_key, value| value.empty? }
  end

  def tls
    certificates_path = "#{ENV.fetch('TRAEFIK_CERT_PATH', '/etc/traefik')}" \
                        "/certificates/#{cloudgw_id}/"
    {
      "certificates" => Certificate.where(account:).map do |certificate|
        {
          "certFile" => "#{certificates_path}#{certificate.name}/" \
                        "#{certificate.cert_path.split('/').last}",
          "keyFile"  => "#{certificates_path}#{certificate.name}/" \
                        "#{certificate.key_path.split('/').last}"
        }
      end
    }
  end

  def service_name(route)
    if route.services.one?
      route.routes_services.first.name
    else
      route.routes_services.first.group_name
    end
  end

  def internal_ping_router
    {
      "alb-ping-internal" => {
        "service"     => "ping@internal",
        "rule"        => "Host(`#{account}.alb.#{ENV.fetch('LOCATION_DOMAIN')}`) " \
                         "&& Path(`/alb/ping`)",
        "entryPoints" => [ "web" ]
      }
    }
  end
end
