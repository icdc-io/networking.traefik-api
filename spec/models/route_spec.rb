require "rails_helper"

RSpec.describe Route, :aggregate_failures do
  # id: 3,
  # name: "Route-15sl7k",
  # hostname: "route-15sl7k.computedev.zby.icdc.io",
  # path: "/",
  # target_port: 12588,
  # insecure: "None",
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
      path:                "/",
      target_port:         5555,
      insecure:            "",
      tls_termination:     "",
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
    expect(create(:route)).to be_valid
  end

  describe "incompatible middleware cleanup" do
    let(:service) { create(:service) }

    it "removes HTTP middleware when changing to tcp passthrough" do
      route = create(:route_http, cloud_gateway:, tls_termination: "edge",
                     insecure: "redirect")
      create(:route_service, route:, service:)

      expect(route.middlewares.where(type: "Middleware::Http::RedirectScheme"))
        .to exist

      updated = route.update(
        { "tls_termination" => "passthrough", "insecure" => "" },
        [ { "id" => service.id } ]
      )

      expect(updated).to be_a(Route::Tcp)
      expect(updated.middlewares).to be_empty
    end
  end
end
