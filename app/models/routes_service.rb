class RoutesService < ApplicationRecord
  belongs_to :route
  belongs_to :service

  validates :name, presence: true, uniqueness: true
  validate :service_port_uniqueness

  before_validation { self.name ||= self.class.unique_name }

  def self.generate_name
    name = Haikunator.haikunate(0)
    name if RoutesService.where(name:).none?
  end

  def self.unique_name(name = generate_name)
    "#{name}-#{maximum(:id).to_i.next}"
  end

  def group_name
    "#{name}-group"
  end

  private

  def service_port_uniqueness
    return if RoutesService
              .joins(:route)
              .where(service_id:, route: { target_port: route.target_port })
              .none?

    errors.add(:base, "Route to service port already created")
  end
end
