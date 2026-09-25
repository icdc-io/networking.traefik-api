class Middleware
  module Http
    class AddPrefix < Middleware
      SCHEME = {
        type:    "AddPrefix",
        options: {
          "prefix" => { default: "", required: true }
        }
      }.freeze

      validate :validate_prefix

      # # Prefixing with /foo
      # http:
      #   middlewares:
      #     add-foo:
      #       addPrefix:
      #         prefix: "/foo"

      private

      def validate_prefix
        return if options.to_h["prefix"].to_s.start_with?("/")

        errors.add("prefix", "option is expected to start with \"/\" " \
                             "for #{pretty_type} middleware, " \
                             "see #{SCHEME[:link]}")
      end

      # Prefix is a path, so it must stay a string even if it looks like a number
      def transform_option_value(key, value)
        return value.to_s if key == "prefix"

        super
      end
    end
  end
end
