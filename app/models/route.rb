class Route < ApplicationRecord
  belongs_to :cloud_gateway
  belongs_to :certificate, optional: true
  has_one :healthcheck, dependent: :destroy

  has_many :routes_services, dependent: :destroy
  has_many :services, through: :routes_services
  has_many :middlewares, dependent: :destroy
  has_many :user_middlewares,
           -> { where.not(type: "Middleware::Http::RedirectScheme") },
           class_name: "Middleware", inverse_of: :route

  attribute :services
  attribute :routes_services
  attribute :cloud_gateway
  attribute :healthcheck

  alias_attribute :cloudgateway, :cloud_gateway

  before_validation { self.ip_version ||= 4 }

  before_validation do
    # TODO: API backward capatibility, should be removed
    self.type ||= tls_termination == "passthrough" ? "Route::Tcp" : "Route::Http"

    unless !type || type&.starts_with?("Route::")
      self.type = "Route::#{type.capitalize}"
    end
  end

  validates :name, presence: true
  validate :name_uniqueness_within_account
  validates :hostname, presence: true
  validates :target_port, numericality: { in: 0..65_535 }, allow_nil: true
  validates :owner, presence: true
  validates :ip_version, inclusion: { in: [ 4, 6 ] }
  validates :type, presence: true
  validates :hostname, uniqueness: {
    scope:   %i[cloud_gateway_id path],
    message: "with this path already exists for this cloud gateway"
  }

  after_save :destroy_incompatible_middlewares!

  def update(data, new_services)
    tls = data["tls_termination"]
    route =
      if tls.nil?
        self
      else
        klass = tls == "passthrough" ? Route::Tcp : Route::Http
        is_a?(klass) ? self : becomes!(klass)
      end

    route.update!(data)

    route.routes_services.destroy_all
    RoutesService.generate_name
    route.send(:update_services, new_services)

    route
  end

  # NOTE: We do not show RedirectScheme middleware because it only applies to
  # http router if insecure == redirect, and all user middlewares appliy to
  # https router in this case.
  def as_json(options = nil)
    super.merge("middlewares" => user_middlewares.as_json,
                "type"        => pretty_type)
  end

  def update_middlewares(params)
    self.middlewares = params.to_a.map do |middleware|
      middleware[:type] = "Middleware::" \
                          "#{pretty_type.capitalize}::" \
                          "#{middleware[:type]}"
      Middleware.new(middleware)
    end
  end

  def pretty_type
    type&.delete_prefix("Route::")&.downcase || type
  end

  private

  def name_uniqueness_within_account
    return if Route
              .joins(:cloud_gateway)
              .where(name:, cloud_gateways: { account: cloud_gateway.account })
              .where.not(id:)
              .none?

    errors.add(:name, "already exists within this account")
  end

  def update_services(new_services)
    return unless new_services

    if new_services.one?
      service = Service.find_by(id: new_services.first["id"])
      RoutesService.create!(
        route:        self,
        service:,
        balance_type: :loadbalancer,
        value:        nil,
        name:         RoutesService.unique_name(name)
      )
    else
      new_services.each do |data|
        RoutesService.create!(
          route:        self,
          service:      Service.find_by(id: data["id"]),
          balance_type: :weighted,
          value:        data["weight"],
          name:         RoutesService.unique_name(name)
        )
      end
    end
  end

  public

  delegate :account, to: :cloud_gateway

  def merge_config(generated_config)
    raise NotImplementedError
  end

  private

  def service_name
    if services.one?
      routes_services.first.name
    else
      routes_services.first.group_name
    end
  end

  def add_services(generated_config)
    services_section = generated_config[pretty_type]["services"]
    route_service = routes_services.first

    if route_service.balance_type == "loadbalancer"
      services_section[route_service.name] = {
        "loadBalancer" => {
          "servers" => lb_server(route_service.service)
        }
      }
    else
      services_section[route_service.group_name] = {
        "weighted" => {
          "services" => weighted(routes_services)
        }
      }
      routes_services.includes(:service).find_each do |routes_service|
        services_section[routes_service.name.to_s] = {
          "loadBalancer" => {
            "servers" => lb_server(routes_service.service)
          }
        }
      end
    end

    healthcheck_section(services_section) if healthcheck_enabled
  end

  def lb_server(service)
    raise NotImplementedError
  end

  def weighted(route_services)
    route_services.map do |route_service|
      {
        "name"   => route_service.name,
        "weight" => route_service.value || 1
      }
    end
  end

  def healthcheck_section(lb_config)
    hc = healthcheck.attributes
                    .except("id", "route_id", "created_at", "updated_at")
                    .compact

    hc["interval"] = "#{hc['interval']}s" if hc["interval"]
    hc["timeout"]  = "#{hc['timeout']}s" if hc["timeout"]

    hc["followRedirects"] = hc.delete("follow_redirects")

    hc.delete_if { |_, v| [ "", {} ].include? v }

    lb_config.each_value do |lb|
      if lb["loadBalancer"]
        lb["loadBalancer"]["healthCheck"] = hc
      elsif lb["weighted"]
        lb["weighted"]["healthCheck"] = {}
      end
    end
  end

  def add_middlewares(generated_config)
    generated_config[pretty_type]["middlewares"].merge!(middlewares.config)
  end

  def destroy_incompatible_middlewares!
    middlewares.incompatible_with(self).destroy_all
  end
end
