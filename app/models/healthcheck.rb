class Healthcheck < ApplicationRecord
  belongs_to :route
  validates :method, inclusion: { in:      %w[GET POST PUT DELETE HEAD],
                                  message: "Unsupported action" }

  validates :port, numericality: { in: 1..65_535 }, allow_nil: true
  validates :interval, :timeout,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil:    true
end
