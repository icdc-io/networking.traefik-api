class Middleware
  module Http
    class ReplacePathRegex < Middleware
      SCHEME = {
        type:    "ReplacePathRegex",
        options: {
          "regex"       => { default:  "", required: true },
          "replacement" => { default:  "", required: false }
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
