require "rails_helper"

RSpec.describe Route::Tcp, :aggregate_failures do
  # id: 3,
  # name: "Route-15sl7k",
  # hostname: "route-15sl7k.computedev.zby.icdc.io",
  # path: "",
  # target_port: 12588,
  # insecure: "",
  # tls_termination: "passthrough",
  # cloud_gateway_id: 3,
  # certificate_id: nil,
  # created_at: Mon, 15 Apr 2024 09:47:49.737346000 UTC +00:00,
  # updated_at: Mon, 15 Apr 2024 09:47:49.737346000 UTC +00:00,
  # owner: "user@example.com",
  # ip_version: 4,
  # healthcheck_enabled: false,
  # services: nil,
  # routes_services: nil,
  # cloud_gateway: nil,
  # healthcheck: nil>

  let(:cloud_gateway) { create(:cloud_gateway) }
  let(:valid_attributes) do
    {
      name:                "Route-15sl7k",
      hostname:            "route-15sl7k.dev.example.com",
      path:                "",
      target_port:         5555,
      insecure:            "",
      tls_termination:     "passthrough",
      cloud_gateway_id:    cloud_gateway.id,
      certificate_id:      nil,
      owner:               "user@example.com",
      ip_version:          4,
      healthcheck_enabled: false
    }
  end
  let(:route) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(route).to be_valid
    expect(create(:route_tcp)).to be_valid
  end

  # Validating insecure & tls_termination:

  # |insecure|tls_termination|valid|tcp|
  # |--------|---------------|-----|---|
  # |""      |passthrough    |+    |+  |
  # |allow   |passthrough    |+    |+  |
  # |redirect|passthrough    |+    |+  |

  it "validates insecure value" do
    route.insecure = "invalid_value"
    expect(route).not_to be_valid
  end

  context "with insecure allow or redirect and passthrough" do
    it "is valid with insecure = \"allow\"" do
      route.insecure = "allow"
      expect(route).to be_valid
    end

    it "is valid with insecure = \"redirect\"" do
      route.insecure = "redirect"
      expect(route).to be_valid
    end
  end
end
