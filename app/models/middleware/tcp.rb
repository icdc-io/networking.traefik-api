class Middleware
  module Tcp
    USER_MIDDLEWARES =
      [
        # Middleware::Tcp::InFlightConn,
        Middleware::Tcp::IpAllowList
      ].freeze
  end
end
