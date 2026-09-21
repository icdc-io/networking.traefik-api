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

      InsecureHttp.from(self).merge_config(generated_config)
    end

    def add_healthcheck(service_configs)
      # NOTE: TCP healtcheck is implemented only in Traefik 3.6+, which is not covered yet with current release
    end

    def lb_server(service)
      service.addresses(ip_version).map do |ip|
        address = ip
        address += ":#{target_port.to_i}" if target_port
        { "address" => address }
      end
    end
  end
end
