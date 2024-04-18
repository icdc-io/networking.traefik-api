require 'rails_helper'
require 'swagger_helper'
require './spec/factories/certificate_helper.rb'
require './spec/factories/route_helper.rb'

describe 'Api::V1::RoutesController', type: :request do
  path "/api/v1/routes" do
    get "Get info about existing routes" do
      tags "Routes"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_MEMBER }

      response(
        "200",
        "Operation successfull"
      ) do

        it 'shows all member\'s routes' do |example|
          gateway_test = FactoryBot.create(:cloud_gateway, :account => 'test')
          gateway_icdc = FactoryBot.create(:cloud_gateway, :account => 'icdc')
          test_count = rand(1..5)
          test_count.times do
            # Member's account + member's email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'test')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_test.id,
              :owner => 'test_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])

            # Member's account + other email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'test')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_test.id,
              :owner => 'not_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])

            # Other account + member's email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'icdc')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_icdc.id,
              :owner => 'test_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])
          end

          get "/api/v1/routes",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count)
          generate_docs(example, response)
        end

        it 'shows all account\'s routes' do |example|
          gateway_test = FactoryBot.create(:cloud_gateway, :account => 'test')
          gateway_icdc = FactoryBot.create(:cloud_gateway, :account => 'icdc')
          test_count = rand(1..5)
          test_count.times do
            # Member's account + member's email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'test')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_test.id,
              :owner => 'test_admin@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])

            # Member's account + other email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'test')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_test.id,
              :owner => 'not_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])

            # Other account + member's email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'icdc')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_icdc.id,
              :owner => 'test_admin@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])
          end

          get "/api/v1/routes",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count * 2)
        end

        it 'shows all routes' do |example|
          gateway_test = FactoryBot.create(:cloud_gateway, :account => 'test')
          gateway_icdc = FactoryBot.create(:cloud_gateway, :account => 'icdc')
          test_count = rand(1..5)
          test_count.times do
            # Member's account + member's email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'test')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_test.id,
              :owner => 'test_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])

            # Member's account + other email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'test')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_test.id,
              :owner => 'not_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])

            # Other account + member's email
            service = FactoryBot.create(:service)
            cert = create_certificate(:account => 'icdc')
            route = FactoryBot.create(
              :route,
              :cloud_gateway_id => gateway_icdc.id,
              :owner => 'test_member@test.com',
              :certificate_id => cert.id
            )
            add_routes_services(route, [{:id => service.id}])
          end

          get "/api/v1/routes",
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

    post "Create a new route" do
      tags "Routes"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_MEMBER }
      parameter name: :request_body, in: :body, required: true,
        schema: {
          type: :object,
          properties: {
            route: {
              type: :object,
              properties: {
                name: { type: :string, example: $route.name },
                hostname: { type: :string, example: $route.hostname },
                target_port: { type: :integer, example: $route.target_port },
                tls_termination: { type: :string, example: $route.tls_termination },
                owner: { type: :string, example: $route.owner },
                cloud_gateway_id: { type: :integer, example: $route.cloud_gateway_id },
                path: { type: :string, example: $route.path },
                source_proto: { type: :string, example: $route.source_proto },
                destination_proto: { type: :string, example: $route.destination_proto },
                ip_version: { type: :integer, example: $route.ip_version },
                labels: { type: :string, example: $route.labels },
                services: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :integer, example: $service.id }
                    }
                  }
                },
                certificate_id: { type: :integer, example: $route.certificate_id },
                insecure: { type: :string, example: $route.insecure }
              }
            }
          }
        }

      response(
        "201",
        "Operation successfull"
      ) do

        it 'creates a new route' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          example.metadata[:operation][:parameters].
            select{|param| param[:name] == :request_body}[0][:schema][:properties][:route][:properties]\
              [:services][:items][:properties][:id][:example] = service.id
          example.metadata[:operation][:parameters].
            select{|param| param[:name] == :request_body}[0][:schema][:properties][:route][:properties]\
              [:certificate_id][:example] = cert.id
          example.metadata[:operation][:parameters].
            select{|param| param[:name] == :request_body}[0][:schema][:properties][:route][:properties]\
              [:cloud_gateway_id][:example] = gateway.id

          request_body = { 'route' => $route.attributes.
            slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                  'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels').
            merge(
              :cloud_gateway_id => gateway.id,
              :certificate_id => cert.id,
              :services => [{ :id => service.id }]
            )
          }
          post '/api/v1/routes',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:created)
          expect(Route.count).to eq(1)
          expect(RoutesService.count).to eq(1)
          expect(
            JSON.parse(response.body, symbolize_names: true).
              except(:id, :created_at, :updated_at, :services,
                     :routes_services, :cloud_gateway, :healthcheck, :healthcheck_enabled)
          ).to eq(
            request_body['route'].symbolize_keys.except(:services)
          )
          expect(JSON.parse(response.body)['services'][0].except('created_at', 'updated_at')).to eq(
            service.attributes.except('created_at', 'updated_at')
          )
          expect(JSON.parse(response.body)['routes_services'][0].except('created_at', 'updated_at')).to eq(
            RoutesService.first.attributes.except('created_at', 'updated_at')
          )
          generate_docs(example, response)
        end

        it 'creates a new route with multiple services' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          services = []
          test_count = rand(2..7)
          test_count.times do
            services << FactoryBot.create(:service)
          end
          cert = create_certificate(:account => 'test')

          request_body = { 'route' => $route.attributes.
            slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                  'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels').
            merge(
              :cloud_gateway_id => gateway.id,
              :certificate_id => cert.id,
              :services => services.map {|service| { :id => service.id, :weight => rand(1..100) }}
            )
          }
          post '/api/v1/routes',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:created)
          expect(Route.count).to eq(1)
          expect(RoutesService.count).to eq(test_count)
          expect(
            JSON.parse(response.body, symbolize_names: true).
              except(:id, :created_at, :updated_at, :services,
                     :routes_services, :cloud_gateway, :healthcheck, :healthcheck_enabled)
          ).to eq(
            request_body['route'].symbolize_keys.except(:services)
          )
          services.each_with_index do |service, index|
            expect(JSON.parse(response.body)['services'][index].except('created_at', 'updated_at')).to eq(
              service.attributes.except('created_at', 'updated_at')
            )
            expect(JSON.parse(response.body)['routes_services'][index].except('created_at', 'updated_at')).to eq(
              RoutesService.all[index].attributes.except('created_at', 'updated_at')
            )
          end
        end

        it 'possible to create more than 1 route to service, but with different ports' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          route = FactoryBot.create(
            :route,
            :target_port => 11111,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
          )
          service = FactoryBot.create(:service)
          add_routes_services(route, [{:id => service.id}])
          request_body = { 'route' => $route.attributes.
            slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                  'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels').
            merge(
              'target_port' => 22222,
              :cloud_gateway_id => gateway.id,
              :services => [{ :id => service.id }]
            )
          }
          post '/api/v1/routes',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:created)
        end
      end

      response(
        "422",
        "Invalid request (Route name should be unique per gateway;" +
        " must be possible to create more than 1 route to service, but with different ports)"
      ) do

        it 'valdates route name on uniqueness among gateway' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          route = FactoryBot.create(
            :route,
            :name => 'test_name',
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
          )
          request_body = { 'route' => $route.attributes.
            slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                  'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels').
            merge(
              'name' => 'test_name',
              :cloud_gateway_id => gateway.id,
              :services => [{ :id => service.id }]
            )
          }
          post '/api/v1/routes',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:unprocessable_entity)
        rescue ActiveRecord::RecordInvalid => e
          expect(e)
        end

        it 'can\'t create more than 1 route to one service port' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          route = FactoryBot.create(
            :route,
            :target_port => 11111,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
          )
          service = FactoryBot.create(:service)
          add_routes_services(route, [{:id => service.id}])
          request_body = { 'route' => route.attributes.
            slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                  'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels').
            merge(
              'target_port' => 11111,
              :cloud_gateway_id => gateway.id,
              :services => [{ :id => service.id }]
            )
          }
          post '/api/v1/routes',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:unprocessable_entity)
        rescue ActiveRecord::RecordInvalid => e
          expect(e)
          generate_docs(example, ActionDispatch::Response.new(422, {}, e.to_json))
        end
      end
    end
  end

  path "/api/v1/routes/{id}" do
    get "Show info about selected route" do
      tags "Routes"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_MEMBER }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }

      response(
        "200",
        "Operation successfull"
      ) do

        it 'shows route details' do |example|
          gateway_test = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway_test.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          set_request_param(example, :id, route.id)

          get "/api/v1/routes/#{route.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['route'].
                 except('created_at','updated_at', 'routes_services', 'services', 'cloud_gateway')).to eq(
            route.attributes.except('created_at', 'updated_at', 'routes_services', 'services', 'cloud_gateway')
          )
          expect(JSON.parse(response.body)['route']['services'][0].except('created_at', 'updated_at')).to eq(
            service.attributes.except('created_at', 'updated_at')
          )
          expect(JSON.parse(response.body)['route']['routes_services'][0].except('created_at', 'updated_at')).to eq(
            routes_service.attributes.except('created_at', 'updated_at')
          )
          generate_docs(example, response)
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if route doesn\'t exist' do |example|
          get "/api/v1/routes/#{rand{1..100}}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'doesn\'t show routes from different account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'not_test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          get "/api/v1/routes/#{route.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'doesn\'t show not own route to member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'not_test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          get "/api/v1/routes/#{route.id}",
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

    put "Add routes" do
      tags "Routes"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_MEMBER }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }
      parameter name: :request_body, in: :body, required: true,
        schema: {
          type: :object,
          properties: {
            route: {
              type: :object,
              properties: {
                name: { type: :string, example: $route.name },
                hostname: { type: :string, example: $route.hostname },
                target_port: { type: :integer, example: $route.target_port },
                tls_termination: { type: :string, example: $route.tls_termination },
                owner: { type: :string, example: $route.owner },
                cloud_gateway_id: { type: :integer, example: $route.cloud_gateway_id },
                path: { type: :string, example: $route.path },
                source_proto: { type: :string, example: $route.source_proto },
                destination_proto: { type: :string, example: $route.destination_proto },
                ip_version: { type: :integer, example: $route.ip_version },
                labels: { type: :string, example: $route.labels },
                services: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: { type: :integer, example: $service.id }
                    }
                  }
                },
                certificate_id: { type: :integer, example: $route.certificate_id },
                insecure: { type: :string, example: $route.insecure }
              }
            }
          }
        }

      response(
        "200",
        "Operation successfull"
      ) do

        it 'updates route' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])

          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          set_request_param(example, :id, route.id)
          example.metadata[:operation][:parameters].
            select{|param| param[:name] == :request_body}[0][:schema][:properties][:route][:properties]\
              [:services][:items][:properties][:id][:example] = service.id
          example.metadata[:operation][:parameters].
            select{|param| param[:name] == :request_body}[0][:schema][:properties][:route][:properties]\
              [:certificate_id][:example] = cert.id
          example.metadata[:operation][:parameters].
            select{|param| param[:name] == :request_body}[0][:schema][:properties][:route][:properties]\
              [:cloud_gateway_id][:example] = gateway.id

          request_body = { 'route' => $route.attributes.
            slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                  'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels').
            merge( 
              :cloud_gateway_id => gateway.id,
              :certificate_id => cert.id,
              :services => [{ :id => service.id }]
            )
          }
          put "/api/v1/routes/#{route.id}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }

          expect(response).to have_http_status(:ok)
          expect(
            JSON.parse(response.body, symbolize_names: true).
              except(:id, :created_at, :updated_at, :services,
                     :routes_services, :cloud_gateway, :healthcheck, :healthcheck_enabled)
          ).to eq(
            request_body['route'].symbolize_keys.except(:services)
          )
          expect(JSON.parse(response.body)['services'][0].except('created_at', 'updated_at')).to eq(
            service.attributes.except('created_at', 'updated_at')
          )
          expect(JSON.parse(response.body)['routes_services'][0].except('created_at', 'updated_at')).to eq(
            RoutesService.last.attributes.except('created_at', 'updated_at')
          )
          generate_docs(example, response)

        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if route doesn\'t exist' do |example|
          put "/api/v1/routes/#{rand{1..100}}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'doesn\'t update routes from different account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'not_test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          put "/api/v1/routes/#{route.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'doesn\'t update not own route to member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'not_test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          put "/api/v1/routes/#{route.id}",
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

    delete "Delete route" do
      tags "Routes"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_MEMBER }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }

      response(
        "204",
        "Operation successfull"
      ) do

        it 'deletes route' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          set_request_param(example, :id, route.id)
          delete "/api/v1/routes/#{route.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:no_content)
          expect(Route.count).to eq(0)
          expect(RoutesService.count).to eq(0)
          generate_docs(example, response)
        end

      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if route doesn\'t exist' do |example|
          delete "/api/v1/routes/#{rand{1..100}}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_LOCATION_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'doesn\'t delete routes from different account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'not_test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          delete "/api/v1/routes/#{route.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'doesn\'t delete not own route to member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          service = FactoryBot.create(:service)
          cert = create_certificate(:account => 'test')
          route = FactoryBot.create(
            :route,
            :cloud_gateway_id => gateway.id,
            :owner => 'not_test_member@test.com',
            :certificate_id => cert.id
          )
          routes_service = add_routes_services(route, [{:id => service.id}])
          delete "/api/v1/routes/#{route.id}",
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
  end
end
