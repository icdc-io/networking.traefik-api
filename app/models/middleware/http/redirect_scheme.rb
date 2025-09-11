class Middleware
  module Http
    class RedirectScheme < Middleware
      SCHEME = {
        type:        pretty_type,
        description: "The RedirectScheme middleware redirects the request if the request scheme is different from the configured scheme.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/redirectscheme/",
        options:     {
          scheme:    {
            description: "Scheme of the new URL.",
            default:     "",
            required:    true
          },
          permanent: {
            description: "Enable a permanent redirection.",
            default:     "false",
            required:    true
          },
          port:      {
            description: "Port of the new URL",
            default:     "",
            required:    true
          }
        }
      }.freeze
    end
  end
end
