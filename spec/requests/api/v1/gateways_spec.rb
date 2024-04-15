require 'rails_helper'
require 'swagger_helper'

describe 'Api::V1::GatewaysController', type: :request, aggregate_failures: true do
  path "/api/v1/gateways" do
    get "List of Traefik Gateways" do
      tags "Gateways"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_ADMIN }

      produces "application/json"

      response(
        "200",
        "Operation successfull"
      ) do

        it 'returns list of account\'s Traefik Gateways' do |example|
          test_count = rand(1..3)
          test_count.times do
            FactoryBot.create(:cloud_gateway, :account => 'test')
            FactoryBot.create(:cloud_gateway, :account => 'icdc')
          end
          get(
            "/api/v1/gateways",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          )
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count)
          generate_docs(example, response)
        end

        it 'returns all Traefik Gateways for location admin' do |example|
          test_count = rand(1..3)
          test_count.times do
            FactoryBot.create(:cloud_gateway, :account => 'test')
            FactoryBot.create(:cloud_gateway, :account => 'icdc')
            FactoryBot.create(:cloud_gateway, :account => 'account')
          end
          get "/api/v1/gateways",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count * 3)
        end
      end
    end

    post "Create a new Traefik Gateway (Register)" do
      tags "Gateways"
      description "This endpoint is called from CloudGateway Automation only.
        So we are not going to provide ability to Account Admins
        to create new gateways"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_LOCATION_ADMIN }
      parameter name: :request_body, in: :body, required: true,
        schema: {
          type: :object,
          properties: {
            name: { type: :string, example: 'vpn-default' },
            cloudgw_id: { type: :string, example: 'a843bf2a-7353-563e-a220-f59949849dba' },
            account: { type: :string, example: 'test' }
          }
        }
      produces "application/json"

      response(
        "201",
        "Operation successfull"
      ) do

        it 'creates a new Traefik Gateway' do |example|
          request_body = get_request_body(example)
          post '/api/v1/gateways',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:created)
          expect(CloudGateway.count).to eq(1)
          generate_docs(example, response)
        end
      end

      response(
        "403",
        "Forbidden for Member, Admin"
      ) do

        it 'is forbidden for Account Admin' do |example|
          request_body = get_request_body(example)
          post '/api/v1/gateways',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:forbidden)
          expect(CloudGateway.count).to eq(0)
          generate_docs(example, response)
        end

        it 'is forbidden for Account Member' do |example|
          request_body = get_request_body(example)
          post '/api/v1/gateways',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:forbidden)
          expect(CloudGateway.count).to eq(0)
        end
      end
    end
  end

  path "/api/v1/gateways/{id}" do
    get "Show a gateway details" do
      tags "Gateways"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_ADMIN }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }

      produces "application/json"

      response(
        "200",
        "Operation successfull"
      ) do

        it 'shows a gateway details (to location admin)' do |example|
          gateway = CloudGateway.create!(
            :name => 'vpn_default',
            :cloudgw_id => 'a843bf2a-7dac-4256-b048-cc1bc0864ccb',
            :account => 'test'
          )
          set_request_param(example, :id, gateway.id)
          get "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).except('created_at', 'updated_at')).to eq(
            gateway.attributes.
              except('created_at', 'updated_at').
              merge('cloudgw_instance' => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}")
          )
          generate_docs(example, response)
        end

        it 'shows a gateway details (to Account Admin)' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')

          get "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).except('created_at', 'updated_at')).to eq(
            gateway.attributes.
              except('created_at', 'updated_at').
              merge('cloudgw_instance' => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}")
          )
        end

        it 'shows a gateway details (to Account Member)' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')

          get "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).except('created_at', 'updated_at')).to eq(
            gateway.attributes.
              except('created_at', 'updated_at').
              merge('cloudgw_instance' => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}")
          )
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if gateway doesn\'t exists' do |example|
          get "/api/v1/gateways/#{rand(1..500)}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'returns \'404\' if the gateway doesn\'t belong to the account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          get "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'returns \'404\' if the gateway doesn\'t belong to the account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          get "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    put "Update Traefik Gateway" do
      tags "Gateways"
      description "Usually use to assign Traefik Gateway to account"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_LOCATION_ADMIN }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }
      parameter name: :request_body, in: :body, required: true,
        schema: {
          type: :object,
          properties: {
            name: { type: :string, example: "new-vpn-#{rand(1..9)}" },
            account: { type: :string, example: 'icdc' }
          }
        }
      produces "application/json"

      response(
        "200",
        "Operation successfull"
      ) do

          it 'updates Traefik Gateway' do |example|
            gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
            set_request_param(example, :id, gateway.id)
            request_body = get_request_body(example)
            put "/api/v1/gateways/#{gateway.id}",
              :params => request_body,
              :headers => {
                :'x-icdc-account' => 'location',
                :'x-icdc-role' => 'admin',
                :Authorization => JWT_LOCATION_ADMIN
              }
            expect(response).to have_http_status(:ok)
            expect(JSON.parse(response.body).except('created_at', 'updated_at')).to eq(
              gateway.attributes.
                except('created_at', 'updated_at').
                merge(
                  "name" => request_body[:name],
                  "account" => request_body[:account],
                  "cloudgw_instance" => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}"
                )
            )
            generate_docs(example, response)
          end

        it 'updates Traefik Gateway (for Location Admin)' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          request_body = {
            :name => 'not-vpn-default',
            :cloudgw_id => 'b954cg3b-8464-674f-b331-g60050950ecb',
            :account => 'not-test'
          }
          put "/api/v1/gateways/#{gateway.id}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).except('created_at', 'updated_at')).to eq(
            gateway.attributes.
              except('created_at', 'updated_at').
              merge(
                "name" => request_body[:name],
                "account" => request_body[:account],
                "cloudgw_instance" => "cloudgw-#{gateway.cloudgw_id.split('-')[0]}"
              )
          )
        end
      end

      response(
        "403",
        "Forbidden for Member, Admin"
      ) do

        it 'is forbidden for Account Member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          put "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:forbidden)
          generate_docs(example, response)
        end

        it 'is forbidden for Account Admin' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          put "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:forbidden)
          generate_docs(example, response)
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if gateway doesn\'t exists' do |example|
          put "/api/v1/gateways/#{rand(1..500)}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end
      end
    end

    delete "Remove Traefik Gateway (un-register)" do
      tags "Gateways"
      description "This endpoint is called from CloudGateway Automation only.
        So we are not going to provide ability to Account Admins
        to create new gateways"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_LOCATION_ADMIN }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }

      produces "application/json"

      response(
        "204",
        "Operation successfull"
      ) do

        it 'removes Traefik Gateway (un-register)' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          set_request_param(example, :id, gateway.id)
          delete "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:no_content)
          expect(CloudGateway.count).to eq(0)
          generate_docs(example, response)
        end
      end

      response(
        "403",
        "Forbidden for Member, Admin"
      ) do

        it 'is forbidden for Admin' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          delete "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:forbidden)
          expect(CloudGateway.count).to eq(1)
          generate_docs(example, response)
        end

        it 'is forbidden for Member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')

          delete "/api/v1/gateways/#{gateway.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:forbidden)
          expect(CloudGateway.count).to eq(1)
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if gateway doesn\'t exists' do |example|
          delete "/api/v1/gateways/#{rand(1..500)}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end
      end
    end
  end

  path "/api/v1/gateways/{uuid}/config" do
    get "Return YAML config for Traefik Gateway" do
      tags "Gateways"

      consumes "application/json"
      parameter name: :uuid,
        description: "Used for simplified authorization for some internal requests from CloudGateway to config.",
        in: :path, required: true,
        schema: { type: :string, example: '' }

      produces ['application/json', 'text/yaml']

      response(
        "200",
        "Operation successfull"
      ) do

        it 'returns config' do |example|
          gateway = FactoryBot.create(
            :cloud_gateway,
            :account => 'test'
          )
          services = 3.times.map { { :service => FactoryBot.create(:service), :weight => rand(1..100).to_f } }
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id,
            :tls_termination => "passthrough",
            :insecure => "redirect"
          )
          routes_service = add_routes_services(route, services.map{ |service| {:id => service[:service].id, :weight => service[:weight]} })

          set_request_param(example, :uuid, gateway.cloudgw_id)
          get "/api/v1/gateways/#{gateway.cloudgw_id}/config"
          expect(response).to have_http_status(:ok)
          yaml = YAML.load(response.body)
          services_block = {
            "#{routes_service.first.name}" => {
              "weighted" => {
                "services" => services.map do |service|
                  {"name" => "#{service[:service].ext_id}-#{route.target_port}", "weight" => service[:weight]}
                end
              }
            }
          }
          services.each do |service|
            services_block.merge!("#{service[:service].ext_id}-#{route.target_port}" => {
                "loadBalancer" => {
                  "servers" => [{ "address" => "#{service[:service].addresses(4)}:#{route.target_port}" }]
                }
              }
            )
          end
          expect(yaml["tcp"]).to eq(
            {
              "routers" => {
                "#{route.name}" => {
                  "service" => routes_service.first.name,
                  "rule"    => "HostSNI(`#{route.hostname}`)",
                  "tls"     => { "passthrough" => true }
                }
              },
              "services" => services_block
            }
          )
          services_block.each do |key, value|
            if services_block[key]["loadBalancer"]
              services_block[key]["loadBalancer"]["servers"] =
                [{ "url" => "http://#{value["loadBalancer"]["servers"][0]["address"]}" }]
            end
          end
          expect(yaml["http"]).to eq(
            {
              "routers" => {
                "alb-ping-internal" => {
                  "service"     => "ping@internal",
                  "rule"        => "Host(`#{gateway.account}.alb.#{ENV.fetch('LOCATION_DOMAIN')}`) && Path(`/alb/ping`)",
                  "entryPoints" => ["web"]
                },
                "#{route.name}-http" => {
                  "service"     => routes_service.first.name,
                  "rule"        => "Host(`#{route.hostname}`)",
                  "middlewares" => ["#{route.name}-redirect"],
                  "entryPoints" => ["web"]
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
              "services" => services_block
            }
          )
          expect(yaml["tls"]).to eq(
            "certificates" => [
              {
                "certFile" => "#{ENV['TRAEFIK_CERT_PATH']}/certificates/#{gateway.cloudgw_id}/#{cert.name}/#{cert.cert_path.split('/').last}",
                "keyFile" => "#{ENV['TRAEFIK_CERT_PATH']}/certificates/#{gateway.cloudgw_id}/#{cert.name}/#{cert.key_path.split('/').last}"
              }
            ]
          )
          generate_docs(example, response, 'text/yaml')
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if gateway doesn\'t exists' do |example|
          get "/api/v1/gateways/#{rand(10000000)}/config"
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response, 'application/json')
        end
      end
    end
  end
end
