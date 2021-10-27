class Route < ApplicationRecord
  belongs_to :cloud_gateway
  #belongs_to :certificate
  has_many :routes_services
  has_many :services, :through => :routes_services

  def update(data, new_services)
    update!(data)

    routes_services.each do |rs|
      rs.destroy!
    end

    new_services.each do |data|
      RoutesService.create!(:route => self, :service => Service.find_by(:id => data['id']), :balance_type => :weighted ,:value => data['weight'])
    end if new_services.count > 1
    RoutesService.create!(:route => self, :service => Service.find_by(:id => new_services.first['id']), :balance_type => :loadbalancer, :value => nil) if new_services.count == 1
  end
end
