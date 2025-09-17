class Middleware
  module Http
    class RedirectScheme < Middleware
      SCHEME = {
        type:        "RedirectScheme",
        description: "The RedirectScheme middleware redirects the request if " \
                     "the request scheme is different from the configured " \
                     "scheme.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/redirectscheme/",
        options:     {
          "scheme"    => {
            description: "Scheme of the new URL.",
            default:     "",
            required:    true
          },
          "permanent" => {
            description: "Enable a permanent redirection.",
            default:     "false",
            required:    false
          },
          "port"      => {
            description: "Port of the new URL",
            default:     "",
            required:    false
          }
        }
      }.freeze
    end
  end
end
