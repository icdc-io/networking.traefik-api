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

  describe "before_save" do
    let(:middleware) do
      create(
        :middleware_http_headers,
        options: expected_api_options
      )
    end
    let(:expected_config_options) do
      {
        "customRequestHeaders.X-Script-Name"             => "test",
        "customRequestHeaders.X-Custom-Request-Header"   => "",
        "customResponseHeaders.X-Custom-Response-Header" => "",
        "sslProxyHeaders.X-Forwarded-Proto"              => "https"
      }
    end
    let(:expected_api_options) do
      {
        "customRequestHeaders"  => "X-Script-Name=test,X-Custom-Request-Header=",
        "customResponseHeaders" => "X-Custom-Response-Header=",
        "sslProxyHeaders"       => "X-Forwarded-Proto=https"
      }
    end

    it "saves options with right values" do
      options = middleware.options
      expected_config_options.each do |key, value|
        expect(options.dig(*key.split('.'))).to eq value
      end
    end

    it "renders options in right format" do
      options = middleware.as_json["options"]
      expected_api_options.each do |key, value|
        expect(options[key]).to eq value
      end
    end
  end
end
