require "rails_helper"

RSpec.describe CloudGateway, :aggregate_failures do
  # id: 4,
  # name: "vpn-8",
  # account: "devel",
  # created_at: Mon, 26 Feb 2024 11:29:30.336962000 UTC +00:00,
  # updated_at: Mon, 26 Feb 2024 11:29:30.336962000 UTC +00:00,
  # cloudgw_id: "429e905f-4a3b-7216-e8f4-567607a6b2fc",

  let(:valid_attributes) do
    {
      name:       "vpn-8",
      account:    "devel",
      cloudgw_id: "429e905f-4a3b-7216-e8f4-567607a6b2fc"
    }
  end
  let(:cloud_gateway) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(cloud_gateway).to be_valid
    expect(create(:cloud_gateway)).to be_valid
  end

  describe "#config" do
    context "with http-only route" do
      let!(:route) do
        create(:route, cloud_gateway:, insecure: "", tls_termination: "")
      end
      let!(:service) { create(:service) }
      let!(:route_service) { create(:route_service, route:, service:) }

      it "returns yaml config with service and http router" do
        config = YAML.load(cloud_gateway.config)
        expect(config["http"]).not_to include("middlewares")
        expect(config.dig("http", "services")&.keys)
          .to contain_exactly(route_service.name)
        routers = config.dig("http", "routers")
        http_router_name = "#{route.name}-http"
        expect(routers.keys)
          .to contain_exactly("alb-ping-internal", http_router_name)
        expect(routers[http_router_name])
          .to eq(
            {
              "entryPoints" => [ "web" ],
              "rule"        => "Host(`#{route.hostname}`)",
              "service"     => route_service.name
            }
          )
      end
    end

    context "with tcp passthrough route" do
      let!(:route) do
        create(:route, cloud_gateway:, insecure: "",
          tls_termination: "passthrough")
      end
      let!(:service) { create(:service) }
      let!(:route_service) { create(:route_service, route:, service:) }

      it "returns yaml config with service and tcp router" do
        config = YAML.load(cloud_gateway.config)
        expect(config["http"])
          .to eq({
                   "routers" => {
                     "alb-ping-internal" => {
                       "service"     => "ping@internal",
                       "rule"        => "Host(`#{cloud_gateway.account}.alb.#{ENV.fetch('LOCATION_DOMAIN')}`) " \
                                        "&& Path(`/alb/ping`)",
                       "entryPoints" => [ "web" ]
                     }
                   }
                 })
        expect(config.dig("tcp", "routers"))
          .to eq({
                   route.name => {
                     "service" => route_service.name,
                     "rule"    => "HostSNI(`#{route.hostname}`)",
                     "tls"     => { "passthrough"=>true }
                   }
                 })
        expect(config.dig("tcp", "services").keys).to eq([ route_service.name ])
      end
    end
  end
end
