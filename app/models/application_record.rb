# frozen_string_literal: true

# ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  include Rbac::Filterer
  self.abstract_class = true
end
