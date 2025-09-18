class Route < ApplicationRecord
  belongs_to :cloud_gateway
  belongs_to :certificate, optional: true
  has_one :healthcheck, dependent: :destroy

  has_many :routes_services, dependent: :destroy
  has_many :services, through: :routes_services

  attribute :services
  attribute :routes_services
  attribute :cloud_gateway
  attribute :healthcheck

  alias_attribute :cloudgateway, :cloud_gateway

  before_validation { self.tls_termination = tls_termination.to_s.downcase }
  before_validation { self.insecure = insecure.to_s.downcase }

  validates :name, uniqueness: { scope: :cloud_gateway }
  validates :insecure, inclusion: { in: [ "", "allow", "redirect" ] }
  validates :tls_termination,
            inclusion: { in: [ "", "edge", "re-encrypt", "passthrough" ] }
  validates :tls_termination,
            inclusion: { in: %w[edge re-encrypt] },
            if:        -> { insecure.in? %w[allow redirect] }

  def update(data, new_services)
    update!(data)

    routes_services.destroy_all
    RoutesService.generate_name
    update_services(new_services)
  end

  private

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

  def http?
    tls_termination == "" || insecure != ""
  end

  def https?
    tls_termination != "" && tls_termination != "passthrough"
  end

  def passthrough?
    tls_termination == "passthrough"
  end

  def redirect?
    insecure == "redirect"
  end

  def route_type
    @route_type ||=
      if passthrough?
        # TODO: UDP?
        "tcp"
      else
        "http"
      end
  end

  def merge_config(generated_config)
    return if services.none?

    case route_type
    when "http"
      add_http_router(generated_config) if http?
      add_https_router(generated_config) if https?
      add_redirect_middleware(generated_config) if redirect?
    when "tcp"
      add_tcp_router(generated_config) if passthrough?
    end

    add_services(generated_config)

    generated_config
  end

  private

  def add_http_router(generated_config)
    router = {
      "service"     => service_name,
      "rule"        => rule,
      "entryPoints" => [ "web" ]
    }

    router["middlewares"] = [ "#{name}-redirect" ] if redirect?

    generated_config["http"]["routers"]["#{name}-http"] = router
  end

  def add_https_router(generated_config)
    router = {
      "service"     => service_name,
      "rule"        => rule,
      "tls"         => certificate ? true : { "certResolver" => "default" },
      "entryPoints" => [ "websecure" ]
    }

    generated_config["http"]["routers"]["#{name}-https"] = router
  end

  def add_tcp_router(generated_config)
    router = {
      "service" => service_name,
      "rule"    => "HostSNI(`#{hostname}`)",
      "tls"     => { "passthrough" => true }
    }

    generated_config["tcp"]["routers"][name] = router
  end

  def add_redirect_middleware(generated_config)
    generated_config["http"]["middlewares"]["#{name}-redirect"] =
      redirect_middleware
  end

  def redirect_middleware
    {
      "redirectScheme" => {
        "scheme"    => "https",
        "permanent" => true
      }
    }
  end

  def service_name
    if services.one?
      routes_services.first.name
    else
      routes_services.first.group_name
    end
  end

  def rule
    if path == "/"
      "Host(`#{hostname}`)"
    else
      "Host(`#{hostname}`) && PathPrefix(`#{path}`)"
    end
  end

  def add_services(generated_config)
    services_section = generated_config[route_type]["services"]
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
      routes_services.each do |routes_service|
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
    ip_version ||= 4
    case route_type
    when "http"
      service.addresses(ip_version).split(",").map do |ip|
        {
          "url" => if target_port
                     "#{schema}://#{ip}:#{target_port.to_i}"
                   else
                     "#{schema}://#{ip}"
                   end
        }
      end
    when "tcp"
      service.addresses(ip_version).split(",").map do |ip|
        {
          "address" => if target_port
                         "#{ip}:#{target_port.to_i}"
                       else
                         ip.to_s
                       end
        }
      end
    end
  end

  def schema
    tls_termination == "re-encrypt" ? "https" : "http"
  end

  def weighted(route_services)
    route_services.map do |route_service|
      {
        "name"   => route_service.name,
        "weight" => route_service.value
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
end
