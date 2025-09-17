class Middleware
  module Http
    class ReplacePath < Middleware
      SCHEME = {
        type:        "ReplacePath",
        description: "The replacePath middleware will replace the actual path with the specified one and store the original path in a X-Replaced-Path header.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/replacepath/",
        options:     {
          "path" => {
            description: "The path option defines the path to use as replacement in the request URL.",
            default:     "",
            required:    true
          }
        }
      }.freeze

      # # Replace the path with /foo
      # http:
      #   middlewares:
      #     test-replacepath:
      #       replacePath:
      #         path: "/foo"
    end
  end
end
