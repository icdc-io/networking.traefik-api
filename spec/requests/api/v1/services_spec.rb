require 'rails_helper'

describe 'Api::V1::ServicesController', :aggregate_failures do
  before do
    User.current_user = User.new(userid: 'test_member@test.com', token: nil,
                                 account: 'test', role: 'member')
    $gateway = create(:cloud_gateway, account: 'test')
    $certificate = create_certificate(account: 'test')
    $certificate_values = $certificate.send(:values)
    $service = create(:service)
    $route = create(
      :route,
      cloud_gateway_id: $gateway.id,
      owner:            'test_member@test.com',
      certificate_id:   $certificate.id
    )
    $routes_service = create(:routes_service, route:   $route,
                                              service: $service).destroy!
    $route.destroy!
    $service.destroy!
    $certificate.destroy!
    $gateway.destroy!
  end

  describe "GET /api/v1/services" do
    it "shows all member's services" do
      test_count = rand(1..20)
      test_count.times do
        create(:service, account: 'test',
                         owner:   'test_member@test.com')
        create(:service, account: 'test',
                         owner:   'not_test_member@test.com')
        create(:service, account: 'not_test',
                         owner:   'test_member@test.com')
      end
      get "/api/v1/services",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "test_member@test.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count)
    end

    it "shows all account's services" do
      test_count = rand(1..20)
      test_count.times do
        create(:service, account: 'test',
                         owner:   'not_test_admin@test.com')
        create(:service, account: 'test',
                         owner:   'test_admin@test.com')
        create(:service, account: 'not_test',
                         owner:   'test_admin@test.com')
      end
      get "/api/v1/services",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 2)
    end

    it "shows all services" do
      test_count = rand(1..20)
      test_count.times do
        create(:service, account: 'test',
                         owner:   'test_location_operator@test.com')
        create(:service, account: 'test',
                         owner:   'not_test_member@test.com')
        create(:service, account: 'not_test',
                         owner:   'test_location_operator@test.com')
      end
      get "/api/v1/services",
          params:  nil,
          headers: {
            "X-Auth-Account": "location",
            "X-Auth-Role":    "operator",
            "X-Auth-User":    "test_location_operator@test.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 3)
    end
  end
end
