class Middleware
  module Http
    class StripPrefixRegex < Middleware
      SCHEME = {
        type:    "StripPrefixRegex",
        options: {
          "regex" => { default: "", required: false }
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
