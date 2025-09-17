require 'rails_helper'

RSpec.describe Middleware::Http::ReplacePathRegex, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::ReplacePathRegex",
      route:,
      options: {
        "regex" => "^/foo/(.*)"
      }
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_replace_path_regex)).to be_valid
  end
end
