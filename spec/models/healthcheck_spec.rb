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

  describe "values rendered into YAML config" do
    # NOTE: multiline values are allowed, YAML renders them safely
    let(:multiline) { "foo\nbar: baz\n" }

    it "is valid with multiline values" do
      healthcheck.assign_attributes(path: multiline, scheme: multiline,
                                    hostname: multiline,
                                    headers:  { multiline => multiline })
      expect(healthcheck).to be_valid
    end

    it "survives YAML round trip without extra keys" do
      attributes = { "path"     => multiline,
                     "hostname" => multiline,
                     "headers"  => { multiline => multiline } }

      expect(YAML.load(attributes.to_yaml)).to eq(attributes)
    end
  end

  describe "numeric values" do
    it "is invalid with port out of range" do
      [ 0, 65_536, "abc" ].each do |port|
        healthcheck.port = port
        expect(healthcheck).not_to be_valid, "#{port.inspect} must be invalid"
      end
    end

    it "is invalid with non positive interval or timeout" do
      healthcheck.interval = 0
      expect(healthcheck).not_to be_valid

      healthcheck.interval = 15
      healthcheck.timeout = -1
      expect(healthcheck).not_to be_valid
    end
  end
end
