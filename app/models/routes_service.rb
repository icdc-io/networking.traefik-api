class RoutesService < ApplicationRecord
  belongs_to :route
  belongs_to :service

  def self.generate_name
    name = Haikunator.haikunate
    return name if RoutesService.where(:name => name).empty?
  end
end
