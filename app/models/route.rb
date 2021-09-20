class Route < ApplicationRecord
  belongs_to :cloud_gateway
  has_and_belongs_to_many :services
  belongs_to :certificate
end
