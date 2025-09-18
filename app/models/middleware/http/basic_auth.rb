class Middleware
  module Http
    class BasicAuth < Middleware
      SCHEME = {
        type:    "BasicAuth",
        options: {
          "users"        => { default:  "",        required: false },
          "usersFile"    => { default:  "",        required: false },
          "realm"        => { default:  "traefik", required: false },
          "headerField"  => { default:  "",        required: false },
          "removeHeader" => { default:  "",        required: false }
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
