require 'rails_helper'

describe 'Api::V1::CertificatesController', :aggregate_failures do
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

  describe "GET /api/v1/certificates" do
    it 'shows all member\'s certificates' do
      create(:cloud_gateway, account: 'test')
      create(:cloud_gateway, account: 'icdc')
      test_count = rand(1..5)
      test_count.times do
        create_certificate(account: 'test')
        create_certificate(account: 'test',
                           owner:   "not_test_member@test.com")
        create_certificate(account: 'icdc')
      end

      get "/api/v1/certificates",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "test_member@test.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count)
    end

    it 'shows all certificates (to location admin)' do
      create(:cloud_gateway, account: 'test')
      create(:cloud_gateway, account: 'icdc')
      test_count = rand(1..5)
      test_count.times do
        create_certificate(account: 'test')
        create_certificate(account: 'icdc')
      end
      get "/api/v1/certificates",
          params:  nil,
          headers: {
            "X-Auth-Account": "location",
            "X-Auth-Role":    "operator",
            "X-Auth-User":    "test_location_operator@test.com"
          }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 2)
    end

    it 'shows all account\'s certificates' do
      create(:cloud_gateway, account: 'test')
      create(:cloud_gateway, account: 'icdc')
      test_count = rand(1..5)
      test_count.times do
        create_certificate(account: 'test')
        create_certificate(account: 'test',
                           owner:   "not_test_member@test.com")
        create_certificate(account: 'icdc')
      end

      get "/api/v1/certificates",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 2)
    end
  end

  describe "POST /api/v1/certificates" do
    it 'creates a new Certificate' do
      gateway = create(:cloud_gateway, account: 'test')
      request_body = {
        'certificate' => {
          'name'  => "alb.computedev.zby.icdc.io",
          'owner' => "test_member@test.com"
        }.merge($certificate_values.stringify_keys.slice('cert', 'key',
                                                         'ca', 'dest_ca'))
      }
      post '/api/v1/certificates',
           params:  request_body,
           headers: {
             "X-Auth-Account": "test",
             "X-Auth-Role":    "member",
             "X-Auth-User":    "test_member@test.com"
           }
      expect(response).to have_http_status(:created)
      expect(Certificate.count).to eq(1)
      response_body = JSON.parse(response.body, symbolize_names: true)
      path = "#{gateway.account}/#{request_body['certificate']['name']}/"
      expect(response_body.except(:created_at, :updated_at, :id,
                                  :values)).to eq(
                                    request_body['certificate'].symbolize_keys.except(:cert, :key, :ca, :dest_ca).merge(
                                      account:      'test',
                                      ca_path:      "#{path}ca",
                                      cert_path:    "#{path}cert",
                                      dest_ca_path: "#{path}dest_ca",
                                      key_path:     "#{path}key"
                                    )
                                  )
      expect(response_body[:values]).to eq(
        request_body['certificate'].symbolize_keys.slice(:cert, :key, :ca, :dest_ca).merge(
          $certificate_values.symbolize_keys,
          valid_from:  "2021-03-30T16:52:40.000Z",
          valid_until: "2021-06-28T16:52:40.000Z"
        )
      )
    end
  end

  describe "GET /api/v1/certificates/:id" do
    it 'shows certificate details' do
      create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'test_member@test.com')
      get "/api/v1/certificates/#{certificate.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "test_member@test.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.except('created_at', 'updated_at',
                                         'values')).to eq(
                                           certificate.attributes.except(
                                             'created_at', 'updated_at', 'values'
                                           )
                                         )
      expect(response.parsed_body['values']).to eq(
        certificate.send(:values).stringify_keys.merge(
          'valid_from'  => "2021-03-30T16:52:40.000Z",
          'valid_until' => "2021-06-28T16:52:40.000Z"
        )
      )
    end

    it 'returns \'404\' if certificate doesn\'t exist' do
      create(:cloud_gateway, account: 'test')
      get "/api/v1/certificates/#{rand(1..100)}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t show certificate from different account' do
      create(:cloud_gateway, account: 'not_test')
      certificate = create_certificate(account: 'not_test',
                                       owner:   'test_member@test.com')
      get "/api/v1/certificates/#{certificate.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t show not own certificate to member' do
      create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'not_test_member@test.com')
      get "/api/v1/certificates/#{certificate.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "test_member@test.com"
          }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/certificates/:id" do
    it 'updates certificate' do
      gateway = create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test')
      request_body = {
        'certificate' => {
          'name' => "new-lb.computedev.zby.icdc.io"
        }.merge($certificate_values.stringify_keys.slice('cert', 'key',
                                                         'ca', 'dest_ca'))
      }
      put "/api/v1/certificates/#{certificate.id}",
          params:  request_body,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:ok)
      response_body = JSON.parse(response.body, symbolize_names: true)
      path = "#{gateway.account}/#{request_body['certificate']['name']}/"
      expect(response_body.except(:created_at, :updated_at, :id,
                                  :values)).to eq(
                                    request_body['certificate'].symbolize_keys
                                      .except(:cert, :key, :ca, :dest_ca)
                                      .merge(
                                        account:      'test',
                                        owner:        'test_member@test.com',
                                        ca_path:      "#{path}ca",
                                        cert_path:    "#{path}cert",
                                        dest_ca_path: "#{path}dest_ca",
                                        key_path:     "#{path}key"
                                      )
                                  )
      expect(response_body[:values]).to eq(
        request_body['certificate'].symbolize_keys.slice(:cert, :key, :ca, :dest_ca).merge(
          $certificate_values.symbolize_keys,
          valid_from:  "2021-03-30T16:52:40.000Z",
          valid_until: "2021-06-28T16:52:40.000Z"
        )
      )
    end

    it 'updates certificate (Member)' do
      gateway = create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'test_member@test.com')
      request_body = {
        'certificate' => {
          'name' => "new-lb.computedev.zby.icdc.io"
        }.merge($certificate_values.stringify_keys.slice('cert', 'key',
                                                         'ca', 'dest_ca'))
      }
      put "/api/v1/certificates/#{certificate.id}",
          params:  request_body,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "test_member@test.com"
          }
      expect(response).to have_http_status(:ok)
      response_body = JSON.parse(response.body, symbolize_names: true)
      path = "#{gateway.account}/#{request_body['certificate']['name']}/"
      expect(response_body.except(:created_at, :updated_at, :id,
                                  :values)).to eq(
                                    request_body['certificate'].symbolize_keys.except(:cert, :key, :ca, :dest_ca).merge(
                                      account:      'test',
                                      owner:        'test_member@test.com',
                                      ca_path:      "#{path}ca",
                                      cert_path:    "#{path}cert",
                                      dest_ca_path: "#{path}dest_ca",
                                      key_path:     "#{path}key"
                                    )
                                  )
      expect(response_body[:values]).to eq(
        request_body['certificate'].symbolize_keys.slice(:cert, :key, :ca, :dest_ca).merge(
          $certificate_values.symbolize_keys,
          valid_from:  "2021-03-30T16:52:40.000Z",
          valid_until: "2021-06-28T16:52:40.000Z"
        )
      )
    end

    it 'returns \'404\' if certificate doesn\'t exist' do
      create(:cloud_gateway, account: 'test')
      request_body = {
        'certificate' => {
          'name' => "new-lb.computedev.zby.icdc.io"
        }.merge($certificate_values.stringify_keys.slice('cert', 'key',
                                                         'ca', 'dest_ca'))
      }
      put "/api/v1/certificates/#{rand(1..100)}",
          params:  request_body,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update certificate from different account' do
      create(:cloud_gateway, account: 'not_test')
      certificate = create_certificate(account: 'not_test',
                                       owner:   'test_admin@test.com')
      request_body = {
        'certificate' => {
          'name' => "new-lb.computedev.zby.icdc.io"
        }.merge($certificate_values.stringify_keys.slice('cert', 'key',
                                                         'ca', 'dest_ca'))
      }
      put "/api/v1/certificates/#{certificate.id}",
          params:  request_body,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "test_admin@test.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update not own certificate for member' do
      create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'not_test_member@test.com')
      request_body = {
        'certificate' => {
          'name' => "new-lb.computedev.zby.icdc.io"
        }.merge($certificate_values.stringify_keys.slice('cert', 'key',
                                                         'ca', 'dest_ca'))
      }
      put "/api/v1/certificates/#{certificate.id}",
          params:  request_body,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "test_member@test.com"
          }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/certificates/:id" do
    it 'deletes certificate' do
      create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'test_admin@test.com')
      delete "/api/v1/certificates/#{certificate.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "admin",
               "X-Auth-User":    "test_admin@test.com"
             }
      expect(response).to have_http_status(:no_content)
      expect(Certificate.count).to eq(0)
    end

    it 'deletes certificate' do
      create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'test_member@test.com')
      delete "/api/v1/certificates/#{certificate.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "member",
               "X-Auth-User":    "test_member@test.com"
             }
      expect(response).to have_http_status(:no_content)
      expect(Certificate.count).to eq(0)
    end

    it 'returns \'404\' if certificate doesn\'t exist' do
      create(:cloud_gateway, account: 'test')
      delete "/api/v1/certificates/#{rand(1..100)}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "admin",
               "X-Auth-User":    "test_admin@test.com"
             }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update certificate from different account' do
      create(:cloud_gateway, account: 'not_test')
      certificate = create_certificate(account: 'not_test',
                                       owner:   'test_admin@test.com')
      delete "/api/v1/certificates/#{certificate.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "admin",
               "X-Auth-User":    "test_admin@test.com"
             }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update not own certificate for member' do
      create(:cloud_gateway, account: 'test')
      certificate = create_certificate(account: 'test',
                                       owner:   'not_test_member@test.com')
      delete "/api/v1/certificates/#{certificate.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "member",
               "X-Auth-User":    "test_member@test.com"
             }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/cert-download/:uuid" do
    it 'returns certificate' do
      gateway = create(:cloud_gateway, account: 'test')
      Sidekiq::Testing.inline! do
        create_certificate
      end
      get "/api/v1/cert-download/#{gateway.cloudgw_id}"
      expect(response).to have_http_status(:ok)
      expect(response["Content-Type"]).to eq("application/zip")
    end

    it 'returns \'404\' if gateway doesn\'t exists' do
      get "/api/v1/cert-download/#{rand(1..1_000_000)}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
