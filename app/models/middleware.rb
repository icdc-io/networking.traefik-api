class Middleware < ApplicationRecord
  belongs_to :route

  def pretty_type
    self.class.name.split("::").last
  end

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
end
