require 'rails_helper'

RSpec.describe Middleware::Http::ReplacePath, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::ReplacePath",
      route:,
      options: {
        "path" => "/foo"
      }
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_replace_path)).to be_valid
  end
end
