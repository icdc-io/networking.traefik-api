# frozen_string_literal: true

require './lib/rbac/rbac'

# ApplicationRecord
class ApplicationRecord < ActiveRecord::Base
  include Rbac
  self.abstract_class = true
end
