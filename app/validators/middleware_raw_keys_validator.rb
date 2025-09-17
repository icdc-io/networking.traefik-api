class MiddlewareRawKeysValidator < ActiveModel::Validator
  def validate(record)
    scheme = record.class::SCHEME
    validate_allowed_keys(record, scheme)
    validate_required_keys(record, scheme)
    validate_required_values(record, scheme)
  end

  private

  def validate_allowed_keys(record, scheme)
    available_keys = scheme[:options].keys
    passed_keys = record.options_lines.pluck(0)
    add_invalid_keys_error(record, passed_keys - available_keys, scheme)
  end

  def add_invalid_keys_error(record, keys, _scheme)
    # message = "option is not available " \
    #           "for #{record.pretty_type} middleware " \
    #           "for #{record.route.pretty_type} route, " \
    #           "see #{scheme[:link]}"
    message = "option is not available"
    keys.each { |key| record.errors.add(key, message) }
  end

  def validate_required_keys(record, scheme)
    required_keys = scheme[:options].select { |_, v| v[:required] }.keys
    passed_keys = record.options_lines.pluck(0)
    add_missing_keys_error(record, required_keys - passed_keys, scheme)
  end

  def add_missing_keys_error(record, keys, _scheme)
    # message = "option is missing " \
    #           "for #{record.pretty_type} middleware " \
    #           "for #{record.route.pretty_type} route, " \
    #           "see #{scheme[:link]}"
    message = "option is missing"
    keys.each { |key| record.errors.add(key, message) }
  end

  def validate_required_values(record, scheme)
    required_keys = scheme[:options].select { |_, v| v[:required] }.keys
    blank_required_keys = record.options_lines.to_h.slice(*required_keys)
                                .select { |_, v| v.blank? }.keys

    add_blank_values_error(record, blank_required_keys, scheme)
  end

  def add_blank_values_error(record, keys, _scheme)
    # message = "option value can not be blank " \
    #           "for #{record.pretty_type} middleware " \
    #           "for #{record.route.pretty_type} route, " \
    #           "see #{scheme[:link]}"
    message = "option value can not be blank"
    keys.each { |key| record.errors.add(key, message) }
  end
end
