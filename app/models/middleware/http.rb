class Middleware
  module Http
    USER_MIDDLEWARES =
      [
        Middleware::Http::AddPrefix,
        Middleware::Http::BasicAuth,
        # Middleware::Http::Buffering,
        # Middleware::Http::Chain,
        # Middleware::Http::CircuitBreaker,
        # Middleware::Http::Compress,
        # Middleware::Http::ContentType,
        # Middleware::Http::DigestAuth,
        # Middleware::Http::Errors,
        # Middleware::Http::ForwardAuth,
        # Middleware::Http::GrpcWeb,
        Middleware::Http::Headers,
        # Middleware::Http::InFlightReq,
        Middleware::Http::IpAllowList,
        # Middleware::Http::PassTlsClientCert,
        Middleware::Http::RateLimit,
        # Middleware::Http::RedirectRegex,
        # Middleware::Http::RedirectScheme, # NOTE: Do not show
        Middleware::Http::ReplacePath,
        Middleware::Http::ReplacePathRegex,
        # Middleware::Http::Retry,
        Middleware::Http::StripPrefix,
        Middleware::Http::StripPrefixRegex
      ].freeze
  end
end
