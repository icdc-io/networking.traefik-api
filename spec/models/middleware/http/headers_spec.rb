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

  I18n.available_locales.each do |locale|
    context "with #{locale} locale" do
      it "has localization for description" do
        expect do
          t_key = "middlewares.http.headers.scheme.description"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      it "has localization for link" do
        expect do
          t_key = "middlewares.http.headers.scheme.link"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      described_class::SCHEME[:options].each_key do |option|
        it "has localization for #{option} option description" do
          expect  do
            t_key =
              "middlewares.http.headers.scheme.options.#{option}.description"
            I18n.t(t_key, locale:, fallback: nil, raise: true)
          end.not_to raise_error
        end
      end
    end
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
