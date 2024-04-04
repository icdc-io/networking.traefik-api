# frozen_string_literal: true

class RoutesService < ApplicationRecord
  belongs_to :route
  belongs_to :service

  validates :name, uniqueness: { message: '(Route to service port already created)' }

  def self.generate_name
    name = Haikunator.haikunate(0)
    return name if RoutesService.where(name:).empty?
  end

  def self.unique_name(name)
    "#{name}-#{maximum(:id).to_i.next}"
  end

  def group_name
    "#{name}-group"
  end
end
