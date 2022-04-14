class Service < ApplicationRecord
  has_many :routes_services, dependent: :destroy
  has_many :routes, :through => :routes_services

  def addresses(ip_type)
    require 'ipaddr'
    if ip_type.to_i == 4
      ipaddresses.split(',').select{ |ip| ip if IPAddr.new(ip).ipv4? }.join(',')
    else
      ipaddresses.split(',').select{ |ip| ip if IPAddr.new(ip).ipv6? }.join(',')
    end

  end
end
