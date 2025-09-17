class Middleware
  module Http
    class IpAllowList < Middleware
      SCHEME = {
        type:        "IpAllowList",
        description: "ipAllowList accepts / refuses requests based on the client IP.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/ipallowlist/",
        options:     {
          "sourceRange"            => {
            description: "List of allowed IPs (or ranges of allowed IPs by using CIDR notation).",
            default:     "",
            required:    true
          },
          "ipStrategy.depth"       => {
            description: "Depth position of the IP to select in the X-Forwarded-For header (starting from the right). 0 means no depth. If greater than the total number of IPs in X-Forwarded-For, then the client IP is empty. If higher than 0, the excludedIPs options is not evaluated.",
            default:     "0",
            required:    false
          },
          "ipStrategy.excludedIPs" => {
            description: "Allows Traefik to scan the X-Forwarded-For header and select the first IP not in the list. If depth is specified, excludedIPs is ignored.",
            default:     "",
            required:    false
          },
          "ipStrategy.ipv6Subnet"  => {
            description: "If ipv6Subnet is provided and the selected IP is IPv6, the IP is transformed into the first IP of the subnet it belongs to.",
            default:     "",
            required:    false
          }
        }
      }.freeze

      # # Accepts request from defined IP
      # http:
      #   middlewares:
      #     test-ipallowlist:
      #       ipAllowList:
      #         sourceRange:
      #           - "127.0.0.1/32"
      #           - "192.168.1.7"
    end
  end
end
