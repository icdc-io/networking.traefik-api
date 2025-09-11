class Middleware
  module Http
    class RateLimit < Middleware
      SCHEME = {
        type:        "RateLimit",
        description: "The rateLimit middleware ensures that services will receive a fair amount of requests, and allows you to define what fair is.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/ratelimit/",
        options:     {
          "average"                                => {
            description: "Number of requests used to define the rate using the period. 0 means no rate limiting.",
            default:     "0",
            required:    false
          },
          "period"                                 => {
            description: "Period of time used to define the rate.",
            default:     "1s",
            required:    false

          },
          "burst"                                  => {
            description: "Maximum number of requests allowed to go through at the very same moment.",
            default:     "1",
            required:    false

          },
          "sourceCriterion.requestHost"            => {
            description: "Whether to consider the request host as the source.",
            default:     "false",
            required:    false

          },
          "sourceCriterion.requestHeaderName"      => {
            description: "Name of the header used to group incoming requests.",
            default:     "",
            required:    false

          },
          "sourceCriterion.ipStrategy.depth"       => {
            description: "Depth position of the IP to select in the X-Forwarded-For header (starting from the right). 0 means no depth. If greater than the total number of IPs in X-Forwarded-For, then the client IP is empty. If higher than 0, the excludedIPs options is not evaluated.",
            default:     "0",
            required:    false

          },
          "sourceCriterion.ipStrategy.excludedIPs" => {
            description: "Allows scanning the X-Forwarded-For header and select the first IP not in the list. If depth is specified, excludedIPs is ignored.",
            default:     "",
            required:    false

          },
          "sourceCriterion.ipStrategy.ipv6Subnet"  => {
            description: "If ipv6Subnet is provided and the selected IP is IPv6, the IP is transformed into the first IP of the subnet it belongs to.",
            default:     "",
            required:    false

          },
          "redis"                                  => {
            description: "The redis configuration enables distributed rate limiting by using Redis to store rate limit tokens across multiple Traefik instances. This allows you to enforce consistent rate limits across a cluster of Traefik proxies.
When Redis is not configured, Traefik uses in-memory storage for rate limiting, which works only for the individual Traefik instance.",
            default:     "",
            required:    false

          },
          "redis.endpoints"                        => {
            description: "List of Redis server endpoints for distributed rate limiting. You can specify multiple endpoints for Redis cluster or high availability setups.",
            default:     "127.0.0.1:6379",
            required:    false

          },
          "redis.username"                         => {
            description: "Username for Redis authentication.",
            default:     "",
            required:    false

          },
          "redis.password"                         => {
            description: "Password for Redis authentication. In Kubernetes, these can be provided via secrets.",
            default:     "",
            required:    false

          },
          "redis.db"                               => {
            description: "Redis database number to select.",
            default:     "0",
            required:    false

          },
          "redis.poolSize"                         => {
            description: "Defines the base number of socket connections in the pool. If set to 0, it defaults to 10 connections per CPU core as reported by runtime.GOMAXPROCS. If there are not enough connections in the pool, new connections will be allocated beyond poolSize, up to maxActiveConns.",
            default:     "0",
            required:    false

          },
          "redis.minIdleConns"                     => {
            description: "Minimum number of idle connections to maintain in the pool. This is useful when establishing new connections is slow. A value of 0 means idle connections are not automatically closed.",
            default:     "0",
            required:    false

          },
          "redis.maxActiveConns"                   => {
            description: "Maximum number of connections the pool can allocate at any given time. A value of 0 means no limit.",
            default:     "0",
            required:    false

          },
          "redis.readTimeout"                      => {
            description: "Timeout for socket reads. If reached, commands will fail with a timeout instead of blocking. Zero means no timeout.",
            default:     "3s",
            required:    false

          },
          "redis.writeTimeout"                     => {
            description: "Timeout for socket writes. If reached, commands will fail with a timeout instead of blocking. Zero means no timeout.",
            default:     "3s",
            required:    false

          },
          "redis.dialTimeout"                      => {
            description: "Timeout for establishing new connections. Zero means no timeout.",
            default:     "5s",
            required:    false

          },
          "redis.tls.ca"                           => {
            description: "Path to the certificate authority used for the secure connection to Redis, it defaults to the system bundle.",
            default:     "",
            required:    false

          },
          "redis.tls.cert"                         => {
            description: "Path to the public certificate used for the secure connection to Redis. When this option is set, the key option is required.",
            default:     "",
            required:    false

          },
          "redis.tls.key"                          => {
            description: "Path to the private key used for the secure connection to Redis. When this option is set, the cert option is required.",
            default:     "",
            required:    false

          },
          "redis.tls.insecureSkipVerify"           => {
            description: "If insecureSkipVerify is true, the TLS connection to Redis accepts any certificate presented by the server regardless of the hostnames it covers.",
            default:     "false",
            required:    false

          }
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

      # before_validation { errors.add(:type, "not implemented") }
    end
  end
end
