class Middleware
  module Http
    class Headers < Middleware
      SCHEME = {
        type:        "Headers",
        description: "The Headers middleware manages the headers of requests and responses.",
        link:        "https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/headers/",
        options:     {
          "customRequestHeaders"              => {
            description: "Lists the header names and values for requests.",
            default:     "",
            required:    false
          },
          "customResponseHeaders"             => {
            description: "Lists the header names and values for responses.",
            default:     "",
            required:    false
          },
          "accessControlAllowCredentials"     => {
            description: "Indicates if the request can include user credentials.",
            default:     "false",
            required:    false
          },
          "accessControlAllowHeaders"         => {
            description: "Specifies allowed request header names.",
            default:     "",
            required:    false
          },
          "accessControlAllowMethods"         => {
            description: "Specifies allowed request methods.",
            default:     "",
            required:    false
          },
          "accessControlAllowOriginList"      => {
            description: "Specifies allowed origins.",
            default:     "",
            required:    false
          },
          "accessControlAllowOriginListRegex" => {
            description: "Allows origins matching regex.",
            default:     "",
            required:    false
          },
          "accessControlExposeHeaders"        => {
            description: "Specifies which headers are safe to expose to the API of a CORS API specification.",
            default:     "",
            required:    false
          },
          "accessControlMaxAge"               => {
            description: "Time (in seconds) to cache preflight requests.",
            default:     "0",
            required:    false
          },
          "addVaryHeader"                     => {
            description: "Used in conjunction with accessControlAllowOriginList to determine whether the Vary header should be added or modified to demonstrate that server responses can differ based on the value of the origin header.",
            default:     "false",
            required:    false
          },
          "allowedHosts"                      => {
            description: "Lists allowed domain names.",
            default:     "",
            required:    false
          },
          "hostsProxyHeaders"                 => {
            description: "Specifies header keys for proxied hostname.",
            default:     "",
            required:    false
          },
          "sslProxyHeaders"                   => {
            description: "Defines a set of header keys with associated values that would indicate a valid HTTPS request. It can be useful when using other proxies (example: \"X-Forwarded-Proto\": \"https\").",
            default:     "",
            required:    false
          },
          "stsSeconds"                        => {
            description: "Max age for Strict-Transport-Security header.",
            default:     "0",
            required:    false
          },
          "stsIncludeSubdomains"              => {
            description: "If set to true, the includeSubDomains directive is appended to the Strict-Transport-Security header.",
            default:     "false",
            required:    false
          },
          "stsPreload"                        => {
            description: "Adds preload flag to STS header.",
            default:     "false",
            required:    false
          },
          "forceSTSHeader"                    => {
            description: "Adds STS header for HTTP connections.",
            default:     "false",
            required:    false
          },
          "frameDeny"                         => {
            description: "Set frameDeny to true to add the X-Frame-Options header with the value of DENY.",
            default:     "false",
            required:    false
          },
          "customFrameOptionsValue"           => {
            description: "allows the X-Frame-Options header value to be set with a custom value. This overrides the FrameDeny option.",
            default:     "",
            required:    false
          },
          "contentTypeNosniff"                => {
            description: "Set contentTypeNosniff to true to add the X-Content-Type-Options header with the value nosniff.",
            default:     "false",
            required:    false
          },
          "browserXssFilter"                  => {
            description: "Set browserXssFilter to true to add the X-XSS-Protection header with the value 1; mode=block.",
            default:     "false",
            required:    false
          },
          "customBrowserXSSValue"             => {
            description: "allows the X-XSS-Protection header value to be set with a custom value. This overrides the BrowserXssFilter option.",
            default:     "false",
            required:    false
          },
          "contentSecurityPolicy"             => {
            description: "allows the Content-Security-Policy header value to be set with a custom value.",
            default:     "false",
            required:    false
          },
          "contentSecurityPolicyReportOnly"   => {
            description: "allows the Content-Security-Policy-Report-Only header value to be set with a custom value.",
            default:     "",
            required:    false
          },
          "publicKey"                         => {
            description: "Implements HPKP for certificate pinning.",
            default:     "",
            required:    false
          },
          "referrerPolicy"                    => {
            description: "Controls forwarding of Referer header.",
            default:     "",
            required:    false
          },
          "permissionsPolicy"                 => {
            description: "allows sites to control browser features.",
            default:     "",
            required:    false
          },
          "isDevelopment"                     => {
            description: "Set true when developing to mitigate the unwanted effects of the AllowedHosts, SSL, and STS options. Usually testing takes place using HTTP, not HTTPS, and on localhost, not your production domain.",
            default:     "false",
            required:    false
          }
        }
      }.freeze

      # http:
      #   middlewares:
      #     testHeader:
      #       headers:
      #         customRequestHeaders:
      #           X-Script-Name: "test"
      #         customResponseHeaders:
      #           X-Custom-Response-Header: "value"
    end
  end
end
