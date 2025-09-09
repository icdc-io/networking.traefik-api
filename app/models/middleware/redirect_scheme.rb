class Middleware
  class RedirectScheme < Middleware
    ALLOWED_OPTIONS  = %i[scheme permanent port].freeze
    REQUIRED_OPTIONS = %i[scheme].freeze

    # # Redirect to https
    # http:
    #   middlewares:
    #     test-redirectscheme:
    #       redirectScheme:
    #         scheme: https
    #         permanent: true
  end
end
