class Route
  class Http < Route
    has_one :redirect_middleware, class_name:  "Middleware::Http::RedirectScheme",
                                  foreign_key: :route_id

    before_validation { self.insecure = insecure.to_s.downcase }
    before_validation { self.tls_termination = tls_termination.to_s.downcase }
    before_validation { update_redirect_middleware }

    validates :path, presence: true
    validates :insecure, inclusion: { in: [ "" ] },
                         if:        -> { tls_termination.empty? }
    validates :insecure, inclusion: { in: [ "", "allow", "redirect" ] },
                         if:        -> { !tls_termination.empty? }
    validates :tls_termination, inclusion: { in: [ "", "re-encrypt", "edge" ] }

    def http? =tls_termination == "" || insecure != ""
    def https? =tls_termination != "" && tls_termination != "passthrough"
    def passthrough? =tls_termination == "passthrough"
    def redirect? =insecure == "redirect"

    def merge_config(generated_config)
      return if services.none?

      add_http_router(generated_config) if http?
      add_https_router(generated_config) if https?

      add_middlewares(generated_config)

      add_services(generated_config)

      generated_config
    end

    private

    def add_http_router(generated_config)
      router = {
        "service"     => service_name,
        "rule"        => rule,
        "entryPoints" => [ "web" ]
      }

      if redirect?
        router["middlewares"] = [ redirect_middleware.name ]
      elsif middlewares.any?
        router["middlewares"] = middlewares.names
      end

      generated_config["http"]["routers"]["#{name}-http"] = router
    end

    def add_https_router(generated_config)
      router = {
        "service"     => service_name,
        "rule"        => rule,
        "tls"         => certificate ? true : { "certResolver" => "default" },
        "entryPoints" => [ "websecure" ]
      }

      mws = redirect? ? user_middlewares : middlewares
      router["middlewares"] = mws.names if mws.any?

      generated_config["http"]["routers"]["#{name}-https"] = router
    end

    def rule
      if path == "/"
        "Host(`#{hostname}`)"
      else
        "Host(`#{hostname}`) && PathPrefix(`#{path}`)"
      end
    end

    def lb_server(service)
      ip_version ||= 4
      service.addresses(ip_version).split(",").map do |ip|
        url = "#{schema}://#{ip}"
        url += ":#{target_port.to_i}" if target_port
        { "url" => url }
      end
    end

    def schema
      tls_termination == "re-encrypt" ? "https" : "http"
    end

    def update_redirect_middleware
      return redirect_middleware&.destroy! unless redirect?

      return if redirect_middleware

      middlewares.new(type:    "Middleware::Http::RedirectScheme",
                      options: { "scheme" => "https", "permanent" => true })
    end
  end
end
