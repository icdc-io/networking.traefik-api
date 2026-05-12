require 'rails_helper'

RSpec.describe Middleware::Http::StripPrefix, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::StripPrefix",
      route:,
      options: {}
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_strip_prefix)).to be_valid
  end

  I18n.available_locales.each do |locale|
    context "with #{locale} locale" do
      it "has localization for description" do
        expect do
          t_key = "middlewares.http.stripPrefix.scheme.description"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      it "has localization for link" do
        expect do
          t_key = "middlewares.http.stripPrefix.scheme.link"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      described_class::SCHEME[:options].each_key do |option|
        it "has localization for #{option} option description" do
          expect  do
            t_key =
              "middlewares.http.stripPrefix.scheme.options.#{option}.description"
            I18n.t(t_key, locale:, fallback: nil, raise: true)
          end.not_to raise_error
        end
      end
    end
  end
end
