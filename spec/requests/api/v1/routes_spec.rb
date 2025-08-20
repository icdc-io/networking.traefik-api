require 'rails_helper'
require './spec/factories/certificate_helper'
require './spec/factories/route_helper'

describe 'Api::V1::RoutesController', :aggregate_failures do
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

  describe "GET /api/v1/routes" do
    it 'shows all member\'s routes' do
      gateway_test = create(:cloud_gateway, account: 'test')
      gateway_icdc = create(:cloud_gateway, account: 'icdc')
      test_count = rand(1..5)
      test_count.times do
        # Member's account + member's email
        service = create(:service)
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'test_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Member's account + other email
        service = create(:service)
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'not_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Other account + member's email
        service = create(:service)
        cert = create_certificate(account: 'icdc')
        route = create(
          :route,
          cloud_gateway_id: gateway_icdc.id,
          owner:            'test_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])
      end

      get "/api/v1/routes",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count)
    end

    it 'shows all account\'s routes' do
      gateway_test = create(:cloud_gateway, account: 'test')
      gateway_icdc = create(:cloud_gateway, account: 'icdc')
      test_count = rand(1..5)
      test_count.times do
        # Member's account + member's email
        service = create(:service)
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'test_admin@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Member's account + other email
        service = create(:service)
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'not_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Other account + member's email
        service = create(:service)
        cert = create_certificate(account: 'icdc')
        route = create(
          :route,
          cloud_gateway_id: gateway_icdc.id,
          owner:            'test_admin@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])
      end

      get "/api/v1/routes",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 2)
    end

    it 'shows all routes' do
      gateway_test = create(:cloud_gateway, account: 'test')
      gateway_icdc = create(:cloud_gateway, account: 'icdc')
      test_count = rand(1..5)
      test_count.times do
        # Member's account + member's email
        service = create(:service)
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'test_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Member's account + other email
        service = create(:service)
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'not_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Other account + member's email
        service = create(:service)
        cert = create_certificate(account: 'icdc')
        route = create(
          :route,
          cloud_gateway_id: gateway_icdc.id,
          owner:            'test_member@test.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])
      end

      get "/api/v1/routes",
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

  describe "POST /api/v1/routes" do
    it 'creates a new route' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')

      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels')
                                        .merge(
                                          cloud_gateway_id: gateway.id,
                                          certificate_id:   cert.id,
                                          services:         [ { id: service.id } ]
                                        ) }
      post '/api/v1/routes',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'member',
             Authorization:    JWT_MEMBER
           }
      expect(response).to have_http_status(:created)
      expect(Route.count).to eq(1)
      expect(RoutesService.count).to eq(1)
      expect(response.parsed_body).to eq(Route.last.as_json)
      expect(response.parsed_body['services'][0]).to eq(service.as_json)
      expect(response.parsed_body['routes_services'][0]).to eq(RoutesService.first.as_json)
    end

    it 'creates a new route with multiple services' do
      gateway = create(:cloud_gateway, account: 'test')
      services = []
      test_count = rand(2..7)
      test_count.times do
        services << create(:service)
      end
      cert = create_certificate(account: 'test')

      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels')
                                        .merge(
                                          cloud_gateway_id: gateway.id,
                                          certificate_id:   cert.id,
                                          services:         services.map do |service|
                                            { id:     service.id,
                                              weight: rand(1..100) }
                                          end
                                        ) }
      post '/api/v1/routes',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'member',
             Authorization:    JWT_MEMBER
           }
      expect(response).to have_http_status(:created)
      expect(Route.count).to eq(1)
      expect(RoutesService.count).to eq(test_count)
      expect(response.parsed_body).to eq(Route.last.as_json)

      services.each_with_index do |service, index|
        expect(response.parsed_body['services'][index]).to eq(service.as_json)
        expect(response.parsed_body['routes_services'][index]).to eq(RoutesService.all[index].as_json)
      end
    end

    it 'possible to create more than 1 route to service, but with different ports' do
      gateway = create(:cloud_gateway, account: 'test')
      route = create(
        :route,
        target_port:      11_111,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com'
      )
      service = create(:service)
      add_routes_services(route, [ { id: service.id } ])
      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels')
                                        .merge(
                                          'target_port'     => 22_222,
                                          :cloud_gateway_id => gateway.id,
                                          :services         => [ { id: service.id } ]
                                        ) }
      post '/api/v1/routes',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'member',
             Authorization:    JWT_MEMBER
           }
      expect(response).to have_http_status(:created)
    end

    it 'valdates route name on uniqueness among gateway' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      create(
        :route,
        name:             'test_name',
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com'
      )
      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels')
                                        .merge(
                                          'name'            => 'test_name',
                                          :cloud_gateway_id => gateway.id,
                                          :services         => [ { id: service.id } ]
                                        ) }
      post '/api/v1/routes',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'member',
             Authorization:    JWT_MEMBER
           }
      expect(response).to have_http_status(:unprocessable_entity)
    rescue ActiveRecord::RecordInvalid => error
      expect(error)
    end

    it 'can\'t create more than 1 route to one service port' do
      gateway = create(:cloud_gateway, account: 'test')
      route = create(
        :route,
        target_port:      11_111,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com'
      )
      service = create(:service)
      add_routes_services(route, [ { id: service.id } ])
      request_body = { 'route' => route.attributes
                                       .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                              'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels')
                                       .merge(
                                         'target_port'     => 11_111,
                                         :cloud_gateway_id => gateway.id,
                                         :services         => [ { id: service.id } ]
                                       ) }
      post '/api/v1/routes',
           params:  request_body,
           headers: {
             "x-icdc-account": 'test',
             "x-icdc-role":    'member',
             Authorization:    JWT_MEMBER
           }
      expect(response).to have_http_status(:unprocessable_entity)
    rescue ActiveRecord::RecordInvalid => error
      expect(error)
    end

    it "renders 404 if cloud_gateway does not exist" do
      create(:cloud_gateway, account: "test")
      service = create(:service)
      cert = create_certificate(account: "test")

      request_body = {
        "route" => $route
                     .attributes
                     .slice("name", "hostname", "target_port", "labels",
                            "tls_termination", "owner", "path", "source_proto",
                            "destination_proto", "ip_version", "insecure")
                     .merge(cloud_gateway_id: 0,
                            certificate_id:   cert.id,
                            services:         [ { id: service.id } ])
      }
      expect do
        post '/api/v1/routes',
             params:  request_body,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'member',
               Authorization:    JWT_MEMBER
             }
      end.not_to change(Route, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "renders 404 if cloud_gateway from another account" do
      gateway = create(:cloud_gateway, account: "not_a_test")
      service = create(:service)
      cert = create_certificate(account: "test")

      request_body = {
        "route" => $route
                     .attributes
                     .slice("name", "hostname", "target_port", "labels",
                            "tls_termination", "owner", "path", "source_proto",
                            "destination_proto", "ip_version", "insecure")
                     .merge(cloud_gateway_id: gateway.id,
                            certificate_id:   cert.id,
                            services:         [ { id: service.id } ])
      }
      expect do
        post '/api/v1/routes',
             params:  request_body,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'member',
               Authorization:    JWT_MEMBER
             }
      end.not_to change(Route, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/routes/:id" do
    it 'shows route details' do
      gateway_test = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway_test.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      routes_service = add_routes_services(route, [ { id: service.id } ])

      get "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['route']
             .except('created_at', 'updated_at', 'routes_services', 'services', 'cloud_gateway')).to eq(
               route.attributes.except('created_at', 'updated_at',
                                       'routes_services', 'services', 'cloud_gateway')
             )
      expect(response.parsed_body['route']['services'][0].except(
               'created_at', 'updated_at'
             )).to eq(
               service.attributes.except('created_at', 'updated_at')
             )
      expect(response.parsed_body['route']['routes_services'][0].except(
               'created_at', 'updated_at'
             )).to eq(
               routes_service.attributes.except('created_at', 'updated_at')
             )
    end

    it 'returns \'404\' if route doesn\'t exist' do
      get "/api/v1/routes/#{rand { 1..100 }}",
          params:  nil,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t show routes from different account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      service = create(:service)
      cert = create_certificate(account: 'not_test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      get "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t show not own route to member' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'not_test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      get "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/routes/:id" do
    it 'updates route' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])

      service = create(:service)
      cert = create_certificate(account: 'test')

      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'source_proto', 'destination_proto', 'ip_version', 'insecure', 'labels')
                                        .merge(
                                          cloud_gateway_id: gateway.id,
                                          certificate_id:   cert.id,
                                          services:         [ { id: service.id } ]
                                        ) }
      put "/api/v1/routes/#{route.id}",
          params:  request_body,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(route.reload.as_json)
      expect(response.parsed_body['services'][0]).to eq(service.reload.as_json)
      expect(response.parsed_body['routes_services'][0]).to eq(route.routes_services.first.as_json)
    end

    it 'returns \'404\' if route doesn\'t exist' do
      put "/api/v1/routes/#{rand { 1..100 }}",
          params:  nil,
          headers: {
            "x-icdc-account": 'location',
            "x-icdc-role":    'operator',
            Authorization:    JWT_LOCATION_OPERATOR
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update routes from different account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      service = create(:service)
      cert = create_certificate(account: 'not_test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      put "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'admin',
            Authorization:    JWT_ADMIN
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update not own route to member' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'not_test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      put "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "x-icdc-account": 'test',
            "x-icdc-role":    'member',
            Authorization:    JWT_MEMBER
          }
      expect(response).to have_http_status(:not_found)
    end

    it "sets certificate_id = nil when send certificate_id = \"\"" do
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: create(:cloud_gateway, account: 'test').id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: create(:service).id } ])

      request_body = { "route" => { "certificate_id" => "" } }

      expect do
        patch "/api/v1/routes/#{route.id}",
              params:  request_body,
              headers: {
                "x-icdc-account": 'test',
                "x-icdc-role":    'member',
                Authorization:    JWT_MEMBER
              }
      end.to change { route.reload.certificate_id }.from(cert.id).to(nil)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/routes/:id" do
    it 'deletes route' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      delete "/api/v1/routes/#{route.id}",
             params:  nil,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'member',
               Authorization:    JWT_MEMBER
             }
      expect(response).to have_http_status(:no_content)
      expect(Route.count).to eq(0)
      expect(RoutesService.count).to eq(0)
    end

    it 'returns \'404\' if route doesn\'t exist' do
      delete "/api/v1/routes/#{rand { 1..100 }}",
             params:  nil,
             headers: {
               "x-icdc-account": 'location',
               "x-icdc-role":    'operator',
               Authorization:    JWT_LOCATION_OPERATOR
             }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t delete routes from different account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      service = create(:service)
      cert = create_certificate(account: 'not_test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      delete "/api/v1/routes/#{route.id}",
             params:  nil,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'admin',
               Authorization:    JWT_ADMIN
             }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t delete not own route to member' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service)
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'not_test_member@test.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      delete "/api/v1/routes/#{route.id}",
             params:  nil,
             headers: {
               "x-icdc-account": 'test',
               "x-icdc-role":    'member',
               Authorization:    JWT_MEMBER
             }
      expect(response).to have_http_status(:not_found)
    end
  end
end
