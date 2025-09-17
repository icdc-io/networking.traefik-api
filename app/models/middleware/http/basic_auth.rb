class Middleware
  module Http
    class BasicAuth < Middleware
      SCHEME = {
        type:        "BasicAuth",
        description: "The basicAuth middleware grants access to services to authorized users only.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/basicauth/",
        options:     {
          "users"        => {
            description: "Array of authorized users. Each user must be declared using the name:hashed-password format.",
            default:     "",
            required:    false
          },
          "usersFile"    => {
            description: "Path to an external file that contains the authorized users for the middleware. The file content is a list of name:hashed-password.",
            default:     "",
            required:    false
          },
          "realm"        => {
            description: "Allow customizing the realm for the authentication.",
            default:     "traefik",
            required:    false
          },
          "headerField"  => {
            description: "Allow defining a header field to store the authenticated user.",
            default:     "",
            required:    false
          },
          "removeHeader" => {
            description: "Allow removing the authorization header before forwarding the request to your service.",
            default:     "",
            required:    false
          }
        }
      }.freeze

      # # Declaring the user list
      # http:
      #   middlewares:
      #     test-auth:
      #       basicAuth:
      #         users:
      #           - "test:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/"
      #           - "test2:$apr1$d9hr9HBB$4HxwgUir3HP4EsggP/QNo0"
    end
  end
end
