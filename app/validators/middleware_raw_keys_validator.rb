class MiddlewareRawKeysValidator < ActiveModel::Validator
  # FIXME: https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/headers/
  # It will cause an error, because CustomRequestHeaders option has key-value format
  # So do not use in Middleware::Http::Headers class
  def validate(record)
    scheme = record.class::SCHEME
    available_keys = scheme[:options].keys
    required_keys = scheme[:options].partition { _2[:required] }.first.pluck(0)
    passed_keys = record.options_lines.pluck(0)

    add_invalid_keys_error(record, passed_keys - available_keys, scheme)
    add_missing_keys_error(record, required_keys - passed_keys, scheme)
  end

  private

  def add_invalid_keys_error(record, keys, scheme)
    message = "option is not available " \
              "for #{record.pretty_type} middleware " \
              "for #{record.route.pretty_type} route, " \
              "see #{scheme[:link]}"
    keys.each { |key| record.errors.add(key, message) }
  end

  def add_missing_keys_error(record, keys, scheme)
    message = "option is missing " \
              "for #{record.pretty_type} middleware " \
              "for #{record.route.pretty_type} route, " \
              "see #{scheme[:link]}"
    keys.each { |key| record.errors.add(key, message) }
  end
end
