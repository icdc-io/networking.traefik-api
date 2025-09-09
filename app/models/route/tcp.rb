class Route
  class Tcp < Route
    before_validation { self.path = "" }
    before_validation { self.insecure = "" }
    before_validation { self.tls_termination = "" }

    validates :path, absence: true
    validates :insecure, absence: true
    validates :tls_termination, absence: true

    def merge_config(generated_config)
      return if services.none?

      add_tcp_router(generated_config)

      add_services(generated_config)

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

    def lb_server(service)
      ip_version ||= 4
      service.addresses(ip_version).split(",").map do |ip|
        address = ip.to_s
        address += ":#{target_port.to_i}" if target_port
        { "address" => address }
      end
    end
  end
end
