class Middleware < ApplicationRecord
  USER_MIDDLEWARES = (Http::USER_MIDDLEWARES + Tcp::USER_MIDDLEWARES).freeze

  belongs_to :route

  before_save { self.options = options_hash }

  validates_with MiddlewareRawKeysValidator
  validates_with MiddlewareRawTypesValidator
  validates_with MiddlewareRouteTypeValidator

  def self.pretty_type
    name.split("::").last
  end

  delegate :pretty_type, to: :class

  def name
    "#{pretty_type.gsub(/([a-z])([A-Z])/, '\1-\2').downcase}-#{id}"
  end

  def config
    middleware = pretty_type.sub(/^(.)/, &:downcase)
    { name => { middleware => options } }
  end

  def self.config
    pluck(:type, :id, :options).to_h do |type, id, options|
      pretty_type = type.split("::").last
      name = "#{pretty_type.gsub(/([a-z])([A-Z])/, '\1-\2').downcase}-#{id}"
      middleware = pretty_type.sub(/^(.)/, &:downcase)
      [ name, middleware => options ]
    end
  end

  def self.names
    pluck(:type, :id).map do |type, id|
      "#{type.split('::').last.gsub(/([a-z])([A-Z])/, '\1-\2').downcase}-#{id}"
    end
  end

  def as_json
    super.merge("type"    => pretty_type,
                "options" => options_lines.to_h)
  end

  def options_lines(hash = options, output = [], prefix = nil)
    return [] unless hash

    hash.each do |key, value|
      key_with_prefix = prefix ? "#{prefix}.#{key}" : key
      if value.is_a? Hash
        options_lines(value, output, key_with_prefix)
      elsif value.is_a? Array
        output << [ key_with_prefix, value.join(",") ]
      else
        output << [ key_with_prefix, value.to_s ]
      end
    end
    output
  end

  private

  def options_hash(lines = options_lines)
    hash = {}
    lines.each do |key, value|
      value = transform_option_value(key, value)
      insert_line_to_hash(key, value, hash)
    end
    hash
  end

  def insert_line_to_hash(key, value, hash)
    return hash[key] = value unless key.include?(".")

    prefix, postfix = key.scan(/^(\w+)\.(.*)$/).first
    hash[prefix] ||= {}
    insert_line_to_hash(postfix, value, hash[prefix])
  end

  # FIXME: https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/redirectscheme/#port
  # Set a string, not a numeric value.
  # What does it mean? Use use value like `port: "3000"` or `port: ":3000"` ?
  def transform_option_value(_key, value)
    case value
    when "true"
      true
    when "false"
      false
    when /^\d*$/
      value.to_i
    when /^\d*\.\d*$/
      value.to_f
    when /,/
      value.split(",")
    else
      value
    end
  end
end
