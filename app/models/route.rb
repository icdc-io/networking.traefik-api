class Route < ApplicationRecord
  belongs_to :cloud_gateway
  belongs_to :certificate, optional: true
  has_many :routes_services, dependent: :destroy
  has_many :services, :through => :routes_services

  attribute :services
  attribute :routes_services
  attribute :cloud_gateway

  alias_attribute :cloudgateway, :cloud_gateway

  validates :name, uniqueness: { scope: :cloud_gateway }

  def update(data, new_services)
    update!(data)

    routes_services.each do |rs|
      rs.destroy!
    end

    if new_services.count == 1
      RoutesService.create!(
        :route => self, 
        :service => Service.find_by(:id => new_services.first['id']), 
        :balance_type => :loadbalancer, 
        :value => nil, 
        :name => Service.find_by(:id => new_services.first['id']).name
      )
    else
      new_services.each do |data|
        name = RoutesService.generate_name
        RoutesService.create!(:route => self, 
          :service => Service.find_by(:id => data['id']), 
          :balance_type => :weighted ,
          :value => data['weight'], 
          :name => name
        )
      end
    end
  end

  def account
    cloud_gateway.account
  end
end
