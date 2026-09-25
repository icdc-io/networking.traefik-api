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

    context "with tcp passthrough route and insecure redirect" do
      let!(:route) do
        create(:route_tcp, cloud_gateway:, insecure: "redirect")
      end
      let!(:service) { create(:service) }
      let!(:route_service) { create(:route_service, route:, service:) }
      let!(:ip) { service.addresses(4).first }
      let(:http_port) { Route::Tcp::InsecureHttp::TARGET_PORT }
      let!(:mw) { "#{route.name}-redirect" }
      let!(:http_router_name) { "#{route.name}-http" }

      it "returns config with tcp router, insecure http router, and redirect middleware" do
        config = YAML.load(cloud_gateway.config)
        expect(config.dig("http", "routers", http_router_name))
          .to eq(
            {
              "service"     => route_service.name,
              "rule"        => "Host(`#{route.hostname}`)",
              "entryPoints" => [ "web" ],
              "middlewares" => [ mw ]
            }
          )
        expect(config.dig("http", "middlewares", mw))
          .to eq({ "redirectScheme" => { "scheme"    => "https",
                                         "permanent" => true } })
        expect(config.dig("http", "services", route_service.name))
          .to eq(
            {
              "loadBalancer" => {
                "servers" => [ { "url" => "http://#{ip}:#{http_port}" } ]
              }
            }
          )
        expect(config.dig("tcp", "services", route_service.name))
          .to eq(
            {
              "loadBalancer" => {
                "servers" => [ { "address" => "#{ip}:#{route.target_port}" } ]
              }
            }
          )
        expect(config.dig("tcp", "routers", route.name))
          .to include("tls" => { "passthrough" => true })
      end
    end

    context "with tcp passthrough route and insecure allow" do
      let!(:route) do
        create(:route_tcp, cloud_gateway:, insecure: "allow")
      end
      let!(:service) { create(:service) }
      let!(:route_service) { create(:route_service, route:, service:) }
      let!(:ip) { service.addresses(4).first }
      let(:http_port) { Route::Tcp::InsecureHttp::TARGET_PORT }
      let!(:http_router_name) { "#{route.name}-http" }
      let!(:redirect_mw) { "#{route.name}-redirect" }

      it "returns config with tcp router and http router without redirect middleware" do
        config = YAML.load(cloud_gateway.config)
        expect(config.dig("http", "routers", http_router_name))
          .to eq(
            {
              "service"     => route_service.name,
              "rule"        => "Host(`#{route.hostname}`)",
              "entryPoints" => [ "web" ]
            }
          )
        expect(config.dig("http", "services", route_service.name))
          .to eq(
            {
              "loadBalancer" => {
                "servers" => [ { "url" => "http://#{ip}:#{http_port}" } ]
              }
            }
          )
        expect(config.dig("tcp", "services", route_service.name))
          .to eq(
            {
              "loadBalancer" => {
                "servers" => [ { "address" => "#{ip}:#{route.target_port}" } ]
              }
            }
          )
        expect(config.dig("http", "middlewares")&.keys || [])
          .not_to include(redirect_mw)
      end
    end

    context "when changing from http edge+redirect to tcp passthrough" do
      let!(:route) do
        create(:route_http, cloud_gateway:, tls_termination: "edge",
               insecure: "redirect")
      end
      let!(:service) { create(:service) }
      let!(:route_service) { create(:route_service, route:, service:) }

      before do
        route.update(
          { "tls_termination" => "passthrough", "insecure" => "" },
          [ { "id" => service.id } ]
        )
      end

      it "returns tcp config without incompatible middlewares" do
        updated_route = Route.find(route.id)
        config = YAML.load(cloud_gateway.config)

        expect(updated_route.middlewares.where("type LIKE ?", "Middleware::Http::%"))
          .to be_none
        expect(config.dig("tcp", "routers", updated_route.name))
          .not_to have_key("middlewares")
        expect(config["tcp"]).not_to have_key("middlewares")
      end
    end

    context "with healthcheck route" do
      let!(:route) do
        create(:route, cloud_gateway:, healthcheck_enabled: true)
      end
      let!(:service) { create(:service) }
      let!(:route_service) { create(:route_service, route:, service:) }
      let!(:healthcheck) { create(:healthcheck, route:, path: "/up") }

      it "returns yaml config with healthcheck" do
        config = YAML.load(cloud_gateway.config)
        service_section = config.dig("http", "services", route_service.name)
        expect(service_section["loadBalancer"].keys).to include("healthCheck")
        healthcheck_section = service_section.dig("loadBalancer", "healthCheck")
        expect(healthcheck_section)
          .to eq(
            {
              "path"            => healthcheck.path,
              "scheme"          => healthcheck.scheme,
              "port"            => healthcheck.port,
              "interval"        => "#{healthcheck.interval}s",
              "timeout"         => "#{healthcheck.timeout}s",
              "hostname"        => healthcheck.hostname,
              "headers"         => healthcheck.headers,
              "followRedirects" => healthcheck.follow_redirects,
              "method"          => healthcheck.method
            }
          )
      end
    end

    context "with multiple routes/services" do
      let!(:route_services) do
        Array.new(2) do
          create(:route_service, route: create(:route, cloud_gateway:))
        end
      end

      it "returns config with multiple services" do
        config = YAML.load(cloud_gateway.config)
        expect(config.dig("http", "services").keys)
          .to match_array(route_services.pluck(:name))
      end
    end
  end
end
