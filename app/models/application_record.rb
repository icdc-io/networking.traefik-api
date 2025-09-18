# ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  require "rbac"
  include Rbac::Filterer

  self.abstract_class = true
end
