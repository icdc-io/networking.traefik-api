class Middleware
  module Http
    class StripPrefixRegex < Middleware
      SCHEME = {
        type:        "StripPrefixRegex",
        description: "The StripPrefixRegex middleware strips the matching " \
                     "path prefix and stores it in an X-Forwarded-Prefix " \
                     "header.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/stripprefixregex/",
        options:     {
          "regex" => {
            description: "List of regular expressions to match the path " \
                         "prefix from the request URL. " \
                         "For instance, /products also matches " \
                         "/products/shoes and /products/shirts.",
            default:     "",
            required:    false
          }
        }
      }.freeze

      # http:
      #   middlewares:
      #     test-stripprefixregex:
      #       stripPrefixRegex:
      #         regex:
      #           - "/foo/[a-z0-9]+/[0-9]+/"
    end
  end
end
