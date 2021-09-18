class Route < ApplicationRecord
  belongs_to :cloudgw
  belongs_to :services
  belongs_to :certificate
end
