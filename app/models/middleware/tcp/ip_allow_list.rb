class Middleware
  module Tcp
    class IpAllowList < Middleware
      SCHEME = {
        type:        "IpAllowList",
        description: "IpAllowList limits allowed requests based on the " \
                     "client IP.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/tcp/middlewares/ipallowlist/",
        options:     {
          "sourceRange" => {
            description: "The sourceRange option sets the allowed IPs " \
                         "(or ranges of allowed IPs by using CIDR notation).",
            default:     "",
            required:    true
          }
        }
      }.freeze

      # # Accepts request from defined IP
      # tcp:
      #   middlewares:
      #     test-ipallowlist:
      #       ipAllowList:
      #         sourceRange:
      #           - "127.0.0.1/32"
      #           - "192.168.1.7"
    end
  end
end
