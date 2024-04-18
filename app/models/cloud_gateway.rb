# frozen_string_literal: true

class CloudGateway < ApplicationRecord
  attribute :cloudgw_instance, :string
  has_many :routes, dependent: :destroy
  validates :cloudgw_id, uniqueness: true

  after_destroy { FileUtils.rm_f("#{ENV.fetch('USERS_CERT_PATH_ARCH')}/#{cloudgw_id}.zip") }

  def config
    generated_config = {}
    generated_config['http'] = http
    generated_config['tcp'] = tcp if routes.where(tls_termination: 'passthrough').any?
    mw = routes.where(insecure: 'redirect').where.not(tls_termination: nil).any? ? middlewares : []
    generated_config['http']['middlewares'] = mw unless mw.empty?
    generated_config['tls'] = tls if Certificate.where(account:).any?
    generated_config.delete_if { |_key, value| value.empty? }.to_yaml.strip
  end

  def cloudgw_instance
    "cloudgw-#{cloudgw_id.split('-').first}"
  end

  private

  def http
    http_block = { 'routers' => internal_ping_router, 'services' => {} }

    routes.where(tls_termination: ['re-encrypt', 'edge', nil]).find_each do |route|
      next if route.services.empty?

      http_block['routers'].merge! routers_http(route)
      http_block['services'].merge! services_section(route, :http)
    end

    routes.where(tls_termination: 'passthrough', insecure: 'redirect').find_each do |route|
      next if route.services.empty?

      http_block['routers'].merge! routers_http(route)
      http_block['services'].merge! services_section(route, :http)
    end

    http_block.delete_if { |_key, value| value.empty? }
  end

  def routers_http(route)
    router = {
      'service' => service_name(route),
      'rule' => rule(route),
      'tls' => route.certificate ? true : { 'certResolver' => 'default' }
    }
    router['middlewares'] = ["#{route.name}-redirect"] if route.insecure == 'redirect' && route.tls_termination

    outp = { "#{route.name}-http" => router.except('tls').merge('entryPoints' => ['web']) }
    if route.tls_termination.in? %w[re-encrypt edge]
      outp["#{route.name}-https"] = router.except('middlewares').merge('entryPoints' => ['websecure'])
    end
    outp
  end

  def rule(route)
    route.path == '/' ? "Host(`#{route.hostname}`)" : "Host(`#{route.hostname}`) && PathPrefix(`#{route.path}`)"
  end

  def tcp
    tcp_block = { 'routers' => {}, 'services' => {} }

    routes.where(tls_termination: ['passthrough']).find_each do |route|
      next if route.services.empty?

      tcp_block['routers'][route.name] = {
        'service' => service_name(route),
        'rule' => "HostSNI(`#{route.hostname}`)",
        'tls' => {
          'passthrough' => true
        }
      }
      tcp_block['services'].merge!(services_section(route, :tcp))
    end

    tcp_block.delete_if { |_key, value| value.empty? }
  end

  def services_section(route, section)
    services = {}
    route_service = route.routes_services.first
    if route_service.balance_type == 'loadbalancer'
      services[route_service.name] = {
        'loadBalancer' => {
          'servers' => lb_server(route_service.service, section, route)
        }
      }
    else
      services[route_service.group_name] = {
        'weighted' => {
          'services' => weighted(route.routes_services)
        }
      }
      route.routes_services.each do |routes_service|
        services["#{routes_service.name}"] = {
          'loadBalancer' => {
            'servers' => lb_server(routes_service.service, section, route)
          }
        }
      end
    end
    services.delete_if { |_key, value| value.empty? }
    healthcheck_section(services, route.healthcheck) if route.healthcheck_enabled
    services
  end

  def healthcheck_section(lb_config, healthcheck)
    healthcheck = healthcheck.attributes.except('id', 'route_id', 'created_at', 'updated_at').compact
    healthcheck['interval'] = "#{healthcheck['interval']}s" if healthcheck['interval']
    healthcheck['timeout'] = "#{healthcheck['timeout']}s" if healthcheck['timeout']
    healthcheck['followRedirects'] = healthcheck.delete('follow_redirects')

    healthcheck = healthcheck.compact.delete_if { |_, v| ['', {}].include? v }

    lb_config.each do |_, lb|
      if lb['loadBalancer']
        lb['loadBalancer']['healthCheck'] = healthcheck
      elsif lb['weighted']
        lb['weighted']['healthCheck'] = {}
      end
    end
  end

  def lb_server(service, section, route)
    ip_version = route.ip_version || 4
    case section
    when :http
      schema = schema(route)
      service.addresses(ip_version).split(',').map do |ip|
        if route.target_port
          { 'url' => "#{schema}://#{ip}:#{route.target_port.to_i}" }
        else
          { 'url' => "#{schema}://#{ip}" }
        end
      end
    when :tcp
      service.addresses(ip_version).split(',').map do |ip|
        if route.target_port
          { 'address' => "#{ip}:#{route.target_port.to_i}" }
        else
          { 'address' => ip.to_s }
        end
      end
    end
  end

  def weighted(route_services)
    route_services.map do |route_service|
      {
        'name' => route_service.name,
        'weight' => route_service.value
      }
    end
  end

  def schema(route)
    return 'https' if route.tls_termination == 're-encrypt'

    'http'
  end

  def middlewares
    block = {}
    routes.where(insecure: 'redirect').find_each do |route|
      next if route.services.empty? || !route.tls_termination

      block["#{route.name}-redirect"] = {
        'redirectScheme' => {
          'scheme' => 'https',
          'permanent' => true
        }
      }
    end
    block.delete_if { |_key, value| value.empty? }
  end

  def tls
    certificates_path = "#{ENV.fetch('TRAEFIK_CERT_PATH')}/certificates/#{cloudgw_id}/"
    {
      'certificates' => Certificate.where(account:).map do |certificate|
        {
          'certFile' => "#{certificates_path}#{certificate.name}/#{certificate.cert_path.split('/').last}",
          'keyFile' => "#{certificates_path}#{certificate.name}/#{certificate.key_path.split('/').last}"
        }
      end
    }
  end

  def service_name(route)
    route.services.count == 1 ? route.routes_services.first.name : route.routes_services.first.group_name
  end

  def internal_ping_router
    {
      'alb-ping-internal' => {
        'service' => 'ping@internal',
        'rule' => "Host(`#{account}.alb.#{ENV.fetch('LOCATION_DOMAIN')}`) && Path(`/alb/ping`)",
        'entryPoints' => ['web']
      }
    }
  end
end
