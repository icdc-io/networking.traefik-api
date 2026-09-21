require 'rails_helper'

RSpec.describe Middleware::Http::AddPrefix, :aggregate_failures do
  let(:route) { create(:route_http) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Http::AddPrefix",
      route:,
      options: {
        "prefix" => "/foo"
      }
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_http_add_prefix)).to be_valid
  end

  it "is invalid when prefix does not start with slash" do
    [ "foo", "11", 11, "" ].each do |prefix|
      middleware.options = { "prefix" => prefix }
      expect(middleware).not_to be_valid, "#{prefix.inspect} must be invalid"
      expect(middleware.errors[:prefix]).to be_present
    end
  end

  it "keeps numeric prefix as string" do
    middleware.options = { "prefix" => "/11" }
    middleware.save!
    expect(middleware.reload.options["prefix"]).to eq("/11")
    expect(middleware.config.values.first["addPrefix"]["prefix"]).to eq("/11")
  end

  I18n.available_locales.each do |locale|
    context "with #{locale} locale" do
      it "has localization for description" do
        expect do
          t_key = "middlewares.http.addPrefix.scheme.description"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      it "has localization for link" do
        expect do
          t_key = "middlewares.http.addPrefix.scheme.link"
          I18n.t(t_key, locale:, fallback: nil, raise: true)
        end.not_to raise_error
      end

      described_class::SCHEME[:options].each_key do |option|
        it "has localization for #{option} option description" do
          expect  do
            t_key =
              "middlewares.http.addPrefix.scheme.options.#{option}.description"
            I18n.t(t_key, locale:, fallback: nil, raise: true)
          end.not_to raise_error
        end
      end
    end
  end
end
