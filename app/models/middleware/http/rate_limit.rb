class Middleware
  module Http
    class RateLimit < Middleware
      SCHEME = {
        type:    "RateLimit",
        link:    "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/ratelimit/",
        options: {
          "average"                                => { default:  "0",
                                                        required: false },
          "period"                                 => { default:  "1s",
                                                        required: false },
          "burst"                                  => { default:  "1",
                                                        required: false },
          "sourceCriterion.requestHost"            => { default:  "false",
                                                        required: false },
          "sourceCriterion.requestHeaderName"      => { default:  "",
                                                        required: false },
          "sourceCriterion.ipStrategy.depth"       => { default:  "0",
                                                        required: false },
          "sourceCriterion.ipStrategy.excludedIPs" => { default:  "",
                                                        required: false },
          "sourceCriterion.ipStrategy.ipv6Subnet"  => { default:  "",
                                                        required: false }
          # # "redis"                                  => { default:  "",
          # #                                               required: false },
          # "redis.endpoints"                        => { default:  "127.0.0.1:6379",
          #                                               required: false },
          # "redis.username"                         => { default:  "",
          #                                               required: false },
          # "redis.password"                         => { default:  "",
          #                                               required: false },
          # "redis.db"                               => { default:  "0",
          #                                               required: false },
          # "redis.poolSize"                         => { default:  "0",
          #                                               required: false },
          # "redis.minIdleConns"                     => { default:  "0",
          #                                               required: false },
          # "redis.maxActiveConns"                   => { default:  "0",
          #                                               required: false },
          # "redis.readTimeout"                      => { default:  "3s",
          #                                               required: false },
          # "redis.writeTimeout"                     => { default:  "3s",
          #                                               required: false },
          # "redis.dialTimeout"                      => { default:  "5s",
          #                                               required: false },
          # "redis.tls.ca"                           => { default:  "",
          #                                               required: false },
          # "redis.tls.cert"                         => { default:  "",
          #                                               required: false },
          # "redis.tls.key"                          => { default:  "",
          #                                               required: false },
          # "redis.tls.insecureSkipVerify"           => { default:  "false",
          #                                               required: false }
        }
      }.freeze

      # # Here, an average of 100 requests per second is allowed.
      # # In addition, a burst of 200 requests is allowed.
      # # Redis distributed rate limiting is configured with all available options.
      # http:
      #   middlewares:
      #     test-ratelimit:
      #       rateLimit:
      #         average: 100
      #         period: 1s
      #         burst: 200
      #         redis:
      #           endpoints:
      #             - "redis-primary.example.com:6379"
      #             - "redis-replica.example.com:6379"
      #           username: "ratelimit-user"
      #           password: "secure-password"
      #           db: 2
      #           poolSize: 50
      #           minIdleConns: 10
      #           maxActiveConns: 200
      #           readTimeout: 3s
      #           writeTimeout: 3s
      #           dialTimeout: 5s
      #           tls:
      #             ca: "/etc/ssl/redis-ca.crt"
      #             cert: "/etc/ssl/redis-client.crt"
      #             key: "/etc/ssl/redis-client.key"
      #             insecureSkipVerify: false
    end
  end
end
