require 'rails_helper'

describe 'Api::V1::GatewaysController', :aggregate_failures do
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

  describe "GET /api/v1/gateways" do
    it 'returns list of account\'s Traefik Gateways' do
      test_count = rand(1..3)
      test_count.times do
        create(:cloud_gateway, account: 'test')
        create(:cloud_gateway, account: 'icdc')
      end
      get(
        "/api/v1/gateways",
        params:  nil,
        headers: {
          "x-icdc-account": 'test',
          "x-icdc-role":    'admin',
          Authorization:    JWT_ADMIN
        }
      )
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count)
    end

    it 'returns all Traefik Gateways for location admin' do
      test_count = rand(1..3)
      test_count.times do
        create(:cloud_gateway, account: 'test')
        create(:cloud_gateway, account: 'icdc')
        create(:cloud_gateway, account: 'account')
      end
      get "/api/v1/gateways",
          params:  nil,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 3)
    end
  end

  describe "POST /api/v1/gateways" do
    it 'creates a new Traefik Gateway' do
      request_body = {
        'name'       => 'vpn-default',
        'cloudgw_id' => 'a843bf2a-7353-563e-a220-f59949849dba',
        'account'    => 'test'
      }
      post '/api/v1/gateways',
           params:  request_body,
           headers: {
             "x-icdc-account": 'location',
             "x-icdc-role":    'operator',
             Authorization:    JWT_LOCATION_OPERATOR
           }
      expect(response).to have_http_status(:created)
      expect(CloudGateway.count).to eq(1)
    end

    it 'is forbidden for Account Admin' do
      request_body = {
        'name'       => 'vpn-default',
        'cloudgw_id' => 'a843bf2a-7353-563e-a220-f59949849dba',
        'account'    => 'test'
      }
      post '/api/v1/gateways',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'admin',
             Authorization:    JWT_ADMIN
           }
      expect(response).to have_http_status(:forbidden)
      expect(CloudGateway.count).to eq(0)
    end

    it 'is forbidden for Account Member' do
      request_body = {
        'name'       => 'vpn-default',
        'cloudgw_id' => 'a843bf2a-7353-563e-a220-f59949849dba',
        'account'    => 'test'
      }
      post '/api/v1/gateways',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'member',
             Authorization:    JWT_MEMBER
           }
      expect(response).to have_http_status(:forbidden)
      expect(CloudGateway.count).to eq(0)
    end
  end

  describe "GET /api/v1/gateways/:id" do
    it 'shows a gateway details (to location admin)' do
      gateway = CloudGateway.create!(
        name:       'vpn_default',
        cloudgw_id: 'a843bf2a-7dac-4256-b048-cc1bc0864ccb',
        account:    'test'
      )
      get "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.except('created_at',
                                         'updated_at')).to eq(
                                           gateway.attributes
                                             .except('created_at', 'updated_at')
                                             .merge('cloudgw_instance' => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}")
                                         )
    end

    it 'shows a gateway details (to Account Admin)' do
      gateway = create(:cloud_gateway, account: 'test')

      get "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.except('created_at',
                                         'updated_at')).to eq(
                                           gateway.attributes
                                             .except('created_at', 'updated_at')
                                             .merge('cloudgw_instance' => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}")
                                         )
    end

    it 'shows a gateway details (to Account Member)' do
      gateway = create(:cloud_gateway, account: 'test')

      get "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.except('created_at',
                                         'updated_at')).to eq(
                                           gateway.attributes
                                             .except('created_at', 'updated_at')
                                             .merge('cloudgw_instance' => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}")
                                         )
    end

    it 'returns \'404\' if gateway doesn\'t exists' do
      get "/api/v1/gateways/#{rand(1..500)}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns \'404\' if the gateway doesn\'t belong to the account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      get "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns \'404\' if the gateway doesn\'t belong to the account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      get "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/gateways/:id" do
    it 'updates Traefik Gateway' do
      gateway = create(:cloud_gateway, account: 'test')
      request_body = {
        'name'    => "new-vpn-#{rand(1..9)}",
        'account' => 'icdc'
      }
      put "/api/v1/gateways/#{gateway.id}",
          params:  request_body,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.except('created_at',
                                         'updated_at')).to eq(
                                           gateway.attributes
                                             .except('created_at', 'updated_at')
                                             .merge(
                                               "name"             => request_body['name'],
                                               "account"          => request_body['account'],
                                               "cloudgw_instance" => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}"
                                             )
                                         )
    end

    it 'updates Traefik Gateway (for Location Admin)' do
      gateway = create(:cloud_gateway, account: 'test')
      request_body = {
        'name'       => 'not-vpn-default',
        'cloudgw_id' => 'b954cg3b-8464-674f-b331-g60050950ecb',
        'account'    => 'not-test'
      }
      put "/api/v1/gateways/#{gateway.id}",
          params:  request_body,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.except('created_at',
                                         'updated_at')).to eq(
                                           gateway.attributes
                                               .except('created_at', 'updated_at')
                                               .merge(
                                                 "name"             => request_body['name'],
                                                 "account"          => request_body['account'],
                                                 "cloudgw_instance" => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}"
                                               )
                                         )
    end

    it 'is forbidden for Account Member' do
      gateway = create(:cloud_gateway, account: 'test')
      put "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for Account Admin' do
      gateway = create(:cloud_gateway, account: 'test')
      put "/api/v1/gateways/#{gateway.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns \'404\' if gateway doesn\'t exists' do
      put "/api/v1/gateways/#{rand(1..500)}",
          params:  nil,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/gateways/:id" do
    it 'removes Traefik Gateway (un-register)' do
      gateway = create(:cloud_gateway, account: 'test')
      delete "/api/v1/gateways/#{gateway.id}",
             params:  nil,
             headers: {
               "x-icdc-account": 'location',
               "x-icdc-role":    'operator',
               Authorization:    JWT_LOCATION_OPERATOR
             }
      expect(response).to have_http_status(:no_content)
      expect(CloudGateway.count).to eq(0)
    end

    it 'is forbidden for Admin' do
      gateway = create(:cloud_gateway, account: 'test')
      delete "/api/v1/gateways/#{gateway.id}",
             params:  nil,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'admin',
               Authorization:    JWT_ADMIN
             }
      expect(response).to have_http_status(:forbidden)
      expect(CloudGateway.count).to eq(1)
    end

    it 'is forbidden for Member' do
      gateway = create(:cloud_gateway, account: 'test')

      delete "/api/v1/gateways/#{gateway.id}",
             params:  nil,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'member',
               Authorization:    JWT_MEMBER
             }
      expect(response).to have_http_status(:forbidden)
      expect(CloudGateway.count).to eq(1)
    end

    it 'returns \'404\' if gateway doesn\'t exists' do
      delete "/api/v1/gateways/#{rand(1..500)}",
             params:  nil,
             headers: {
               "x-icdc-account": 'location',
               "x-icdc-role":    'operator',
               Authorization:    JWT_LOCATION_OPERATOR
             }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/gateways/:uuid/config" do
    it 'returns config' do
      gateway = create(
        :cloud_gateway,
        account: 'test'
      )
      services = Array.new(3) do
        { service: create(:service), weight: rand(1..100).to_f }
      end
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id,
        tls_termination:  "edge",
        insecure:         "redirect"
      )
      routes_service = add_routes_services(route, services.map do |service|
        { id: service[:service].id, weight: service[:weight] }
      end)

      get "/api/v1/gateways/#{gateway.cloudgw_id}/config"
      expect(response).to have_http_status(:ok)
      yaml = YAML.load(response.body)
      services_block = {
        routes_service.first.group_name.to_s => {
          "weighted" => {
            "services" => services.map do |service|
              { "name"   => service[:service].routes_services.first.name.to_s,
                "weight" => service[:weight] }
            end
          }
        }
      }
      services.each do |service|
        services_block.merge!(service[:service].routes_services.first.name.to_s => {
                                "loadBalancer" => {
                                  "servers" => [ { "address" => "#{service[:service].addresses(4)}:#{route.target_port}" } ]
                                }
                              })
      end
      expect(yaml["tcp"]).to be_nil
      services_block.each do |key, value|
        if services_block[key]["loadBalancer"]
          services_block[key]["loadBalancer"]["servers"] =
            [ { "url" => "http://#{value['loadBalancer']['servers'][0]['address']}" } ]
        end
      end
      expect(yaml["http"]).to eq(
        {
          "routers"     => {
            "alb-ping-internal"   => {
              "service"     => "ping@internal",
              "rule"        => "Host(`#{gateway.account}.alb.#{ENV.fetch('LOCATION_DOMAIN')}`) && Path(`/alb/ping`)",
              "entryPoints" => [ "web" ]
            },
            "#{route.name}-http"  => {
              "service"     => routes_service.first.group_name,
              "rule"        => "Host(`#{route.hostname}`)",
              "middlewares" => [ "#{route.name}-redirect" ],
              "entryPoints" => [ "web" ]
            },
            "#{route.name}-https" => {
              "entryPoints" => [ "websecure" ],
              "rule"        => "Host(`#{route.hostname}`)",
              "service"     => routes_service.first.group_name,
              "tls"         => true
            }
          },
          "middlewares" => {
            "#{route.name}-redirect" => {
              "redirectScheme" => {
                "scheme"    => "https",
                "permanent" => true
              }
            }
          },
          "services"    => services_block
        }
      )
      expect(yaml["tls"]).to eq(
        "certificates" => [
          {
            "certFile" => "#{ENV.fetch('TRAEFIK_CERT_PATH', '/etc/traefik')}" \
                          "/certificates/#{gateway.cloudgw_id}/#{cert.name}/#{cert.cert_path.split('/').last}",
            "keyFile"  => "#{ENV.fetch('TRAEFIK_CERT_PATH', '/etc/traefik')}" \
                          "/certificates/#{gateway.cloudgw_id}/#{cert.name}/#{cert.key_path.split('/').last}"
          }
        ]
      )
    end

    it 'returns \'404\' if gateway doesn\'t exists' do
      get "/api/v1/gateways/#{rand(10_000_000)}/config"
      expect(response).to have_http_status(:not_found)
    end
  end
end
