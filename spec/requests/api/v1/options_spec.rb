require 'rails_helper'

RSpec.describe "Api::V1::OptionsController", :aggregate_failures do
  describe "GET /options/middlewares" do
    context "for member user role" do
      let(:headers) do
        { "X-Auth-Account": "test",
          "X-Auth-Role":    "member",
          "X-Auth-User":    "member@example.com" }
      end

      context "without route_type param" do
        it 'renders user middlewares schemes' do
          get("/api/v1/options/middlewares", headers:)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.size).to eq(Middleware::USER_MIDDLEWARES.size)
        end
      end

      context "with route_type param" do
        it 'renders user middlewares schemes for http routes' do
          params = { route_type: "http" }
          get("/api/v1/options/middlewares", headers:, params:)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.size).to eq(Middleware::Http::USER_MIDDLEWARES.size)
        end

        it 'renders user middlewares schemes for tcp routes' do
          params = { route_type: "tcp" }
          get("/api/v1/options/middlewares", headers:, params:)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body.size).to eq(Middleware::Tcp::USER_MIDDLEWARES.size)
        end

        it "renders error when route_type invalid" do
          params = { route_type: "invalid_type" }
          get("/api/v1/options/middlewares", headers:, params:)
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.parsed_body).to eq(
            { "code" => "ENT034", "data" => nil, "errors" => [],
              "message" => "Invalid route type", "status" => 422 }
          )
        end
      end

      context "with en locale" do
        before { headers["Accept-Language"] = "en" }

        it "renders localized options" do
          params = { route_type: "http" }
          get("/api/v1/options/middlewares", headers:, params:)

          scheme = response.parsed_body.find { |mw| mw["type"] == "AddPrefix" }
          expect(scheme["description"])
            .to eq("The AddPrefix middleware updates the path of a request " \
                   "before forwarding it.")
          expect(scheme["link"])
            .to eq("https://doc.traefik.io/traefik/reference/" \
                   "routing-configuration/http/middlewares/addprefix/")
          expect(scheme.dig("options", "prefix", "description"))
            .to eq("String to add before the current path in the " \
                   "requested URL. It should include a leading slash " \
                   "(/).")
        end
      end

      context "with ru locale" do
        before { headers["Accept-Language"] = "ru" }

        it "renders localized options" do
          params = { route_type: "http" }
          get("/api/v1/options/middlewares", headers:, params:)

          scheme = response.parsed_body.find { |mw| mw["type"] == "AddPrefix" }
          expect(scheme["description"])
            .to eq("Модификатор AddPrefix обновляет путь запроса перед его " \
                   "перенаправлением.")
          expect(scheme["link"])
            .to eq("https://doc.traefik.io/traefik/reference/" \
                   "routing-configuration/http/middlewares/addprefix/")
          expect(scheme.dig("options", "prefix", "description"))
            .to eq("Строка, которую нужно добавить перед текущим путем в " \
                   "запрашиваемом URL. Она должна включать ведущий слеш (/).")
        end
      end

      context "without locale" do
        before { headers.delete("Accept-Language") }

        it "renders options in en locale" do
          params = { route_type: "http" }
          get("/api/v1/options/middlewares", headers:, params:)

          scheme = response.parsed_body.find { |mw| mw["type"] == "AddPrefix" }
          expect(scheme["description"])
            .to eq("The AddPrefix middleware updates the path of a request " \
                   "before forwarding it.")
          expect(scheme["link"])
            .to eq("https://doc.traefik.io/traefik/reference/" \
                   "routing-configuration/http/middlewares/addprefix/")
          expect(scheme.dig("options", "prefix", "description"))
            .to eq("String to add before the current path in the " \
                   "requested URL. It should include a leading slash " \
                   "(/).")
        end
      end

      context "with another locale" do
        before { headers["Accept-Language"] = "xx" }

        it "renders options in en locale" do
          params = { route_type: "http" }
          get("/api/v1/options/middlewares", headers:, params:)

          scheme = response.parsed_body.find { |mw| mw["type"] == "AddPrefix" }
          expect(scheme["description"])
            .to eq("The AddPrefix middleware updates the path of a request " \
                   "before forwarding it.")
          expect(scheme["link"])
            .to eq("https://doc.traefik.io/traefik/reference/" \
                   "routing-configuration/http/middlewares/addprefix/")
          expect(scheme.dig("options", "prefix", "description"))
            .to eq("String to add before the current path in the " \
                   "requested URL. It should include a leading slash " \
                   "(/).")
        end
      end
    end
  end
end
