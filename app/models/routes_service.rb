class RoutesService < ApplicationRecord
  belongs_to :route
  belongs_to :service

  validates :name, presence: true, uniqueness: true
  validates :service_id, uniqueness: { scope: :route_id }
  validate :validate_weight, if: lambda {
    weighted? && (new_record? || will_save_change_to_value?)
  }

  before_validation { self.name ||= self.class.unique_name }

  def self.generate_name
    name = Haikunator.haikunate(0)
    name if RoutesService.where(name:).none?
  end

  def self.unique_name(name = generate_name)
    "#{name}-#{maximum(:id).to_i.next}"
  end

  def weighted?
    balance_type.to_s == "weighted"
  end

  private

  # Traefik accepts only integer weights, so check raw value before it is
  # casted to float (3.5 or "abc" must not pass)
  def validate_weight
    weight = value_before_type_cast
    return if weight.nil?
    return if weight.to_s.match?(/\A\d+\z/) && weight.to_i >= 1

    errors.add(:weight, "must be an integer greater than or equal to 1")
  end
end
