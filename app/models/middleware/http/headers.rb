class Middleware
  module Http
    class Headers < Middleware
      SCHEME = {
        type:    "Headers",
        options: {
          "customRequestHeaders"              => { default:  "",
                                                   required: false },
          "customResponseHeaders"             => { default:  "",
                                                   required: false },
          "accessControlAllowCredentials"     => { default:  "false",
                                                   required: false },
          "accessControlAllowHeaders"         => { default:  "",
                                                   required: false },
          "accessControlAllowMethods"         => { default:  "",
                                                   required: false },
          "accessControlAllowOriginList"      => { default:  "",
                                                   required: false },
          "accessControlAllowOriginListRegex" => { default:  "",
                                                   required: false },
          "accessControlExposeHeaders"        => { default:  "",
                                                   required: false },
          "accessControlMaxAge"               => { default:  "0",
                                                   required: false },
          "addVaryHeader"                     => { default:  "false",
                                                   required: false },
          "allowedHosts"                      => { default:  "",
                                                   required: false },
          "hostsProxyHeaders"                 => { default:  "",
                                                   required: false },
          "sslProxyHeaders"                   => { default:  "",
                                                   required: false },
          "stsSeconds"                        => { default:  "0",
                                                   required: false },
          "stsIncludeSubdomains"              => { default:  "false",
                                                   required: false },
          "stsPreload"                        => { default:  "false",
                                                   required: false },
          "forceSTSHeader"                    => { default:  "false",
                                                   required: false },
          "frameDeny"                         => { default:  "false",
                                                   required: false },
          "customFrameOptionsValue"           => { default:  "",
                                                   required: false },
          "contentTypeNosniff"                => { default:  "false",
                                                   required: false },
          "browserXssFilter"                  => { default:  "false",
                                                   required: false },
          "customBrowserXSSValue"             => { default:  "false",
                                                   required: false },
          "contentSecurityPolicy"             => { default:  "false",
                                                   required: false },
          "contentSecurityPolicyReportOnly"   => { default:  "",
                                                   required: false },
          "publicKey"                         => { default:  "",
                                                   required: false },
          "referrerPolicy"                    => { default:  "",
                                                   required: false },
          "permissionsPolicy"                 => { default:  "",
                                                   required: false },
          "isDevelopment"                     => { default:  "false",
                                                   required: false }
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

      def options_lines(hash = options.dup, output = [], prefix = nil)
        format_header_options_lines(hash, output) unless prefix
        super
      end

      private

      def transform_option_value(key, value)
        if %w[customRequestHeaders
              customResponseHeaders
              sslProxyHeaders].include?(key)
          return transform_header_option_value(key, value)
        end

        super
      end

      def format_header_options_lines(hash, output)
        return [] unless hash

        %w[customRequestHeaders
           customResponseHeaders
           sslProxyHeaders].each do |key|
          next unless hash.include?(key)

          headers_value = hash.delete(key)
          output << if headers_value.is_a? Hash
            [ key, headers_value.map { |k, v| "#{k}=#{v}" }.join(",") ]
          elsif headers_value.is_a? Array
            [ key, headers_value.join(",") ]
          else
            [ key, headers_value ]
          end
        end

        output
      end

      def transform_header_option_value(_key, value)
        value.split(",").to_h do |key_value|
          header = key_value.split("=")
          header[1] = header[1].to_s
          header
        end
      end
    end
  end
end
