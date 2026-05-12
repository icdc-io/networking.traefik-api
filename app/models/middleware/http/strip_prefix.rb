class Middleware
  module Http
    class StripPrefix < Middleware
      SCHEME = {
        type:    "StripPrefix",
        options: {
          "prefixes" => { default: "", required: false }
        }
      }.freeze

      # # Strip prefix /foobar and /fiibar
      # http:
      #   middlewares:
      #     test-stripprefix:
      #       stripPrefix:
      #         prefixes:
      #           - "/foobar"
      #           - "/fiibar"
    end
  end
end
