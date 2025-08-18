require "rails_helper"

RSpec.describe Route, :aggregate_failures do
  # id: 3,
  # name: "Route-15sl7k",
  # hostname: "route-15sl7k.computedev.zby.icdc.io",
  # path: "/",
  # target_port: 12588,
  # insecure: "None",
  # tls_termination: "passthrough",
  # labels: "6X",
  # cloud_gateway_id: 3,
  # certificate_id: nil,
  # created_at: Mon, 15 Apr 2024 09:47:49.737346000 UTC +00:00,
  # updated_at: Mon, 15 Apr 2024 09:47:49.737346000 UTC +00:00,
  # owner: "test_member@test.com",
  # source_proto: "tcp",
  # destination_proto: "tcp",
  # ip_version: "4",
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
      insecure:            "None",
      tls_termination:     "passthrough",
      labels:              "6X",
      cloud_gateway_id:    cloud_gateway.id,
      certificate_id:      nil,
      owner:               "user@example.com",
      source_proto:        "tcp",
      destination_proto:   "tcp",
      ip_version:          "4",
      healthcheck_enabled: false
    }
  end
  let(:route) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(route.valid?).to be(true)
    expect(create(:route)&.valid?).to be(true)
  end

  # Validating name

  # Validating hostname

  # Validating path

  # Validating target_port

  # Validating insecure

  # Validating tls_termination

  it "validates valid tsl_termination values" do
    %w[edge re-encrypt passthrough].each do |value|
      route.tls_termination = value
      expect(route.valid?).to be(true)
    end
  end

  it "validates invalid tsl_termination values" do
    [ "none", "", nil ].each do |value|
      route.tls_termination = value
      expect(route.valid?).to be(false)
    end
  end

  # Validating labels

  # Validating source_proto

  # Validating destination_proto

  # Validating ip_version

  # Validating healthcheck_enabled
end
