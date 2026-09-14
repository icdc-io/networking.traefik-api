class Route
  class Tcp < Route
    before_validation { self.path = "" }
    before_validation { self.insecure = insecure.to_s.downcase }
    before_validation { self.tls_termination = "passthrough" }

    validates :path, absence: true
    validates :insecure, inclusion: { in: [ "", "allow", "redirect" ] }
    validates :tls_termination, inclusion: { in: [ "passthrough" ] }

    def merge_config(generated_config)
      return if services.none?

      add_tcp_router(generated_config)

      add_middlewares(generated_config)

      add_services(generated_config)
      add_insecure_http(generated_config)

      generated_config
    end

    private

    def add_tcp_router(generated_config)
      router = {
        "service" => service_name,
        "rule"    => "HostSNI(`#{hostname}`)",
        "tls"     => { "passthrough" => true }
      }
      router["middlewares"] = middlewares.names if middlewares.any?

      generated_config["tcp"]["routers"][name] = router
    end

    def add_insecure_http(generated_config)
      return unless %w[allow redirect].include?(insecure)

      add_insecure_http_services(generated_config)
      add_insecure_http_router(generated_config)
    end

    def add_insecure_http_services(generated_config)
      http_services = generated_config["http"]["services"]
      route_service = routes_services.first

      if route_service.balance_type == "loadbalancer"
        http_services[route_service.name] = {
          "loadBalancer" => {
            "servers" => lb_server_http(route_service.service)
          }
        }
      else
        http_services[route_service.group_name] = {
          "weighted" => {
            "services" => weighted(routes_services)
          }
        }
        routes_services.includes(:service).find_each do |rs|
          http_services[rs.name.to_s] = {
            "loadBalancer" => {
              "servers" => lb_server_http(rs.service)
            }
          }
        end
      end

      healthcheck_section(http_services) if healthcheck_enabled
    end

    def add_insecure_http_router(generated_config)
      router = {
        "service"     => service_name,
        "rule"        => "Host(`#{hostname}`)",
        "entryPoints" => [ "web" ]
      }

      if insecure == "redirect"
        router["middlewares"] = [ add_redirect_middleware(generated_config) ]
      end

      generated_config["http"]["routers"]["#{name}-http"] = router
    end

    def add_redirect_middleware(generated_config)
      mw = "#{name}-redirect"
      generated_config["http"]["middlewares"][mw] = {
        "redirectScheme" => {
          "scheme"    => "https",
          "permanent" => true
        }
      }
      mw
    end

    def lb_servers(service, key:, prefix:)
      ip_version ||= 4
      service.addresses(ip_version).split(",").map do |ip|
        endpoint = "#{prefix}#{ip}"
        endpoint += ":#{target_port.to_i}" if target_port
        { key => endpoint }
      end
    end

    def lb_server_http(service)
      lb_servers(service, key: "url", prefix: "http://")
    end

    def lb_server(service)
      lb_servers(service, key: "address", prefix: "")
    end
  end
end
