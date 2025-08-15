class Healthcheck < ApplicationRecord
  belongs_to :route
  validates :method,
            inclusion: {
              in:      %w[
                GET
                POST
                PUT
                DELETE
                HEAD
              ],
              message: "Unsupported action"
            }
end
