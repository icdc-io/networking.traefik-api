class Service < ApplicationRecord
 has_many :routes_services
 has_many :routes, :through => :routes_services
end
