class Middleware
  module Tcp
    class IpAllowList < Middleware
      SCHEME = {
        type:    "IpAllowList",
        options: {
          "sourceRange" => { default: "", required: true }
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
