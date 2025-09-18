class Middleware
  module Http
    class AddPrefix < Middleware
      SCHEME = {
        type:    "AddPrefix",
        options: {
          "prefix" => { default: "", required: true }
        }
      }.freeze

      # # Prefixing with /foo
      # http:
      #   middlewares:
      #     add-foo:
      #       addPrefix:
      #         prefix: "/foo"
    end
  end
end
