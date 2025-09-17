class Middleware
  module Http
    class ReplacePathRegex < Middleware
      SCHEME = {
        type:        "ReplacePathRegex",
        description: "The replacePathRegex middleware will replace the matching path with the specified one and store the original path in an X-Replaced-Path header.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/replacepathregex/",
        options:     {
          "regex"       => {
            description: "Regular expression to match and capture the path from the request URL.",
            default:     "",
            required:    true
          },
          "replacement" => {
            description: "Replacement path format, which can include captured variables. $1x is equivalent to ${1x}, not ${1}x (see Regexp.Expand), so use ${1} syntax.",
            default:     "",
            required:    false
          }
        }
      }.freeze

      # # Replace path with regex
      # http:
      #   middlewares:
      #     test-replacepathregex:
      #       replacePathRegex:
      #         regex: "^/foo/(.*)"
      #         replacement: "/bar/$1"
    end
  end
end
