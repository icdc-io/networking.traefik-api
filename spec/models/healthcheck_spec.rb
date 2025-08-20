require 'rails_helper'

RSpec.describe Healthcheck, :aggregate_failures do
  let(:route) { create(:route) }
  let(:valid_attributes) do
    {
      route_id:         route.id,
      path:             "",
      scheme:           "http",
      port:             3000,
      interval:         15,
      timeout:          3,
      hostname:         "example.com",
      headers:          { "X-Platform-Account" => "test",
                          "X-Platform-Role"    => "admin" },
      follow_redirects: false,
      method:           "HEAD"
    }
  end
  let(:healthcheck) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(healthcheck).to be_valid
    expect(create(:healthcheck)).to be_valid
  end
end
