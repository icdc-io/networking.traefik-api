class Middleware
  module Http
    class StripPrefix < Middleware
      SCHEME = {
        type:        "StripPrefix",
        description: "The StripPrefix middleware strips the matching path " \
                     "prefix and stores it in an X-Forwarded-Prefix header.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/stripprefix/",
        options:     {
          "prefixes" => {
            description: "List of prefixes to strip from the request URL. " \
                         "If your backend is serving assets " \
                         "(for example, images or JavaScript files), " \
                         "it can use the X-Forwarded-Prefix header to " \
                         "construct relative URLs.",
            default:     "",
            required:    false
          }
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
