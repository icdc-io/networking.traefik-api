class Service < ApplicationRecord
  include RequestHelper

  has_many :routes_services, dependent: :destroy
  has_many :routes, through: :routes_services

  def addresses(ip_type)
    require "ipaddr"
    if ip_type.to_i == 4
      ipaddresses.split(",").select do |ip|
        ip if IPAddr.new(ip).ipv4?
      end.join(",")
    else
      ipaddresses.split(",").select do |ip|
        ip if IPAddr.new(ip).ipv6?
      end.join(",")
    end
  end
end
