class Middleware
  module Http
    class AddPrefix < Middleware
      SCHEME = {
        type:        "AddPrefix",
        description: "The addPrefix middleware updates the path of a request before forwarding it.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/addprefix/",
        options:     {
          "prefix" => {
            description: "String to add before the current path in the requested URL. It should include a leading slash (/).",
            default:     "",
            required:    true
          }
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
