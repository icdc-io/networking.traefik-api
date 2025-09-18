class MiddlewareRouteTypeValidator < ActiveModel::Validator
  def validate(record)
    type = record.route.type.split("::").second
    return if record.route_type == type

    record.errors.add(:type, "should be one of Middleware::#{type}:: classes")
  end
end
