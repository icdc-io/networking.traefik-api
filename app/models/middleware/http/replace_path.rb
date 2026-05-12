class Middleware
  module Http
    class ReplacePath < Middleware
      SCHEME = {
        type:    "ReplacePath",
        options: {
          "path" => { default: "", required: true }
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
