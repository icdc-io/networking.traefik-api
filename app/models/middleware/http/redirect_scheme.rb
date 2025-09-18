class Middleware
  module Http
    class RedirectScheme < Middleware
      SCHEME = {
        type:    "RedirectScheme",
        options: {
          "scheme"    => { default:  "",      required: true },
          "permanent" => { default:  "false", required: false },
          "port"      => { default:  "",      required: false }
        }
      }.freeze
    end
  end
end
