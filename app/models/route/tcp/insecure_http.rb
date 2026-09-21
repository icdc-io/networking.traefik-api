class Route
  class Tcp < Route
    # In-memory HTTP route rendered for Route::Tcp with insecure allow/redirect.
    # It is never persisted and shares id with the TCP route, so services and
    # healthcheck are loaded from the TCP route associations.
    class InsecureHttp < Route::Http
      REDIRECT_OPTIONS = { "scheme" => "https", "permanent" => true }.freeze
      # NOTE: we assume here that 80 is used for HTTP,
      #       because we know HTTPS port only, which do not accept HTTP traffic.
      # TODO: maybe add new parameter `insecure_target_port` to address such case ?
      TARGET_PORT = 80

      def self.from(tcp_route)
        attributes = tcp_route.attributes_before_type_cast
                              .slice(*column_names)
                              .merge("type"            => nil,
                                     "tls_termination" => "",
                                     "path"            => "/",
                                     "target_port"     => TARGET_PORT)

        instantiate(attributes).tap(&:readonly!)
      end

      def pretty_type = "http"

      private

      # TCP middlewares are not applicable to HTTP router
      def http_middleware_names
        redirect? ? [ redirect_middleware_name ] : []
      end

      def add_middlewares(generated_config)
        return unless redirect?

        generated_config["http"]["middlewares"][redirect_middleware_name] = {
          "redirectScheme" => REDIRECT_OPTIONS.dup
        }
      end

      def redirect_middleware_name = "#{name}-redirect"
    end
  end
end
