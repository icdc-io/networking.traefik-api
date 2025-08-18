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

  validates :name, uniqueness: { scope: :cloud_gateway }

  def update(data, new_services)
    update!(data)

    routes_services.each(&:destroy!)
    name = RoutesService.generate_name
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

  delegate :account, to: :cloud_gateway
end
