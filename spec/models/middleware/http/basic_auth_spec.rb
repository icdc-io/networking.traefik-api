require 'rails_helper'

RSpec.describe Middleware::Http::BasicAuth, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::BasicAuth",
      route:,
      options: {}
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_basic_auth)).to be_valid
  end
end
