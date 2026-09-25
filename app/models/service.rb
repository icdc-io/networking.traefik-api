require "ipaddr"

class Service < ApplicationRecord
  has_many :routes_services, dependent: :destroy
  has_many :routes, through: :routes_services

  # NOTE: multiple IP addresses can be returned (e.g. multiple NICs on single VM, virtual IPs)
  #       Healthcheck must be configured
  def addresses(ip_version)
    ip_version ||= 4
    # NOTE: ipv4 addresses go first then ipv6, so ipv6 is used only when ipv4 is not available
    ips = ipaddresses.split(",")
    # Traefik requires square bracket in the config
    if ip_version.to_i == 6
      return ips.select { |ip| IPAddr.new(ip).ipv6? }
                .map { |ip| "[#{ip}]" }
    end

    ips.select { |ip| IPAddr.new(ip).ipv4? }
  end
end
