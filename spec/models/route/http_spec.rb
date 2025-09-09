require "rails_helper"

RSpec.describe Route::Http, :aggregate_failures do
  # id: 3
  # name: "Route-15sl7k"
  # hostname: "route-15sl7k.computedev.zby.icdc.io"
  # path: "/"
  # target_port: 12588
  # insecure: ""
  # tls_termination: ""
  # cloud_gateway_id: 3
  # certificate_id: nil
  # created_at: Mon, 15 Apr 2024 09:47:49.737346000 UTC +00:00
  # updated_at: Mon, 15 Apr 2024 09:47:49.737346000 UTC +00:00
  # owner: "user@example.com"
  # ip_version: 4
  # healthcheck_enabled: false

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
    expect(create(:route_http)).to be_valid
  end

  # Validating insecure & tls_termination:

  # |insecure|tls_termination|valid|http|https|
  # |--------|---------------|-----|----|-----|
  # |""      |""             |+    |+   |     |
  # |""      |re-encrypt     |+    |    |+    |
  # |""      |edge           |+    |    |+    |
  # |allow   |""             |     |    |     |
  # |allow   |re-encrypt     |+    |+   |+    |
  # |allow   |edge           |+    |+   |+    |
  # |redirect|""             |     |    |     |
  # |redirect|re-encrypt     |+    |+   |+    |
  # |redirect|edge           |+    |+   |+    |

  it "validates insecure value" do
    route.insecure = 'invalid_value'
    expect(route).not_to be_valid
  end

  it "validates tls_termination value" do
    route.tls_termination = 'invalid_value'
    expect(route).not_to be_valid
  end

  context "with insecure and tls_termination validation" do
    let(:insecure)        { "" }
    let(:tls_termination) { "" }

    before do
      route.insecure = insecure
      route.tls_termination = tls_termination
    end

    context "with insecure = \"\"" do
      let(:insecure) { "" }

      context "with tls_termination = \"\"" do
        let(:tls_termination) { "" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is http" do
          expect(route.http?).to be(true)
        end

        it "is not https" do
          expect(route.https?).to be(false)
        end
      end

      context "with tls_termination = \"re-encrypt\"" do
        let(:tls_termination) { "re-encrypt" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is not http" do
          expect(route.http?).to be(false)
        end

        it "is https" do
          expect(route.https?).to be(true)
        end
      end

      context "with tls_termination = \"edge\"" do
        let(:tls_termination) { "edge" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is not http" do
          expect(route.http?).to be(false)
        end

        it "is https" do
          expect(route.https?).to be(true)
        end
      end
    end

    context "with insecure = \"allow\"" do
      let(:insecure) { "allow" }

      context "with tls_termination = \"\"" do
        let(:tls_termination) { "" }

        it "is not valid" do
          expect(route).not_to be_valid
        end
      end

      context "with tls_termination = \"re-encrypt\"" do
        let(:tls_termination) { "re-encrypt" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is http" do
          expect(route.http?).to be(true)
        end

        it "is https" do
          expect(route.https?).to be(true)
        end
      end

      context "with tls_termination = \"edge\"" do
        let(:tls_termination) { "edge" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is http" do
          expect(route.http?).to be(true)
        end

        it "is https" do
          expect(route.https?).to be(true)
        end
      end
    end

    context "with insecure = \"redirect\"" do
      let(:insecure) { "redirect" }

      context "with tls_termination = \"\"" do
        let(:tls_termination) { "" }

        it "is not valid" do
          expect(route).not_to be_valid
        end
      end

      context "with tls_termination = \"re-encrypt\"" do
        let(:tls_termination) { "re-encrypt" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is http" do
          expect(route.http?).to be(true)
        end

        it "is https" do
          expect(route.https?).to be(true)
        end
      end

      context "with tls_termination = \"edge\"" do
        let(:tls_termination) { "edge" }

        it "is valid" do
          expect(route).to be_valid
        end

        it "is http" do
          expect(route.http?).to be(true)
        end

        it "is https" do
          expect(route.https?).to be(true)
        end
      end
    end
  end
end
