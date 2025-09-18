class Middleware
  module Http
    class IpAllowList < Middleware
      SCHEME = {
        type:    "IpAllowList",
        options: {
          "sourceRange"            => { default:  "",  required: true },
          "ipStrategy.depth"       => { default:  "0", required: false },
          "ipStrategy.excludedIPs" => { default:  "",  required: false },
          "ipStrategy.ipv6Subnet"  => { default:  "",  required: false }
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
