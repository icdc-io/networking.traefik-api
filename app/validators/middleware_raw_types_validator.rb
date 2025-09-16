class MiddlewareRawTypesValidator < ActiveModel::Validator
  # FIXME: https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/headers/
  # It will cause an error, because CustomRequestHeaders option has key-value format
  # So do not use in Middleware::Http::Headers class
  def validate(record)
    scheme = record.class::SCHEME

    record.options_lines.each do |key, value|
      validate_value_type(record, key, value, scheme)
    end
  end

  private

  def validate_value_type(record, key, value, scheme)
    default = scheme.dig(:options, key, :default)
    case default
    when "true", "false"
      validate_boolean(record, key, value, scheme)
    when /^\d+(ms|s|m|h)$/
      validate_time_interval(record, key, value, scheme)
    when /^[-+]?(\d*\.)?\d+$/
      validate_number(record, key, value, scheme)
    when /^-\d+$/
      validate_signed_integer(record, key, value, scheme)
    end
  end

  def validate_boolean(record, key, value, scheme)
    return if %w[true false].include?(value)

    message = "option is expected to have boolean value " \
              "for #{record.pretty_type} middleware " \
              "for #{record.route.pretty_type} route, " \
              "see #{scheme[:link]}"
    record.errors.add(key, message)
  end

  def validate_time_interval(record, key, value, scheme)
    return if /^\d+(ms|s|m|h)$/.match?(value)

    message = "option is expected to have time interval value " \
              "for #{record.pretty_type} middleware " \
              "for #{record.route.pretty_type} route, " \
              "see #{scheme[:link]}"
    record.errors.add(key, message)
  end

  def validate_number(record, key, value, scheme)
    return if /^[-+]?(\d*\.)?\d+$/.match?(value)

    message = "option is expected to have numeric value " \
              "for #{record.pretty_type} middleware " \
              "for #{record.route.pretty_type} route, " \
              "see #{scheme[:link]}"
    record.errors.add(key, message)
  end
end
