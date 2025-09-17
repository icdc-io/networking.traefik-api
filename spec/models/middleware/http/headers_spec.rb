require 'rails_helper'

RSpec.describe Middleware::Http::Headers, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::Headers",
      route:,
      options: {}
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_headers)).to be_valid
  end
end
