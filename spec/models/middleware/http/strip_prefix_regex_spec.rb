require 'rails_helper'

RSpec.describe Middleware::Http::StripPrefixRegex, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::StripPrefixRegex",
      route:,
      options: {}
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_strip_prefix_regex)).to be_valid
  end
end
