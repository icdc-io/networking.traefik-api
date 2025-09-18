require 'rails_helper'

RSpec.describe Middleware::Http::IpAllowList, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::IpAllowList",
      route:,
      options: {
        "sourceRange" => "127.0.0.1/32,192.168.1.7"
      }
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_ip_allow_list)).to be_valid
  end

  I18n.available_locales.each do |locale|
    context "with #{locale} locale" do
      it "has localization for description" do
        expect do
          t_key = "middlewares.http.ipAllowList.scheme.description"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      it "has localization for link" do
        expect do
          t_key = "middlewares.http.ipAllowList.scheme.link"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      described_class::SCHEME[:options].each_key do |option|
        it "has localization for #{option} option description" do
          expect  do
            t_key =
              "middlewares.http.ipAllowList.scheme.options.#{option}.description"
            I18n.t(t_key, locale:, fallback: nil, raise: true)
          end.not_to raise_error
        end
      end
    end
  end
end
