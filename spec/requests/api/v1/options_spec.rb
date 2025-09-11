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
          expect(response.parsed_body).to eq(
            Middleware::USER_MIDDLEWARES.map { _1::SCHEME }.as_json
          )
        end
      end

      context "with route_type param" do
        it 'renders user middlewares schemes for http routes' do
          params = { route_type: "http" }
          get("/api/v1/options/middlewares", headers:, params:)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq(
            Middleware::Http::USER_MIDDLEWARES.map { _1::SCHEME }.as_json
          )
        end

        it 'renders user middlewares schemes for tcp routes' do
          params = { route_type: "tcp" }
          get("/api/v1/options/middlewares", headers:, params:)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq(
            Middleware::Tcp::USER_MIDDLEWARES.map { _1::SCHEME }.as_json
          )
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
    end
  end
end
