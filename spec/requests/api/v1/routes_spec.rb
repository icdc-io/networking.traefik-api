require 'rails_helper'

describe 'Api::V1::RoutesController', :aggregate_failures do
  let(:account) { 'test' }
  let(:user)    { 'member@example.com' }
  let(:role)    { 'member' }
  let(:headers) do
    { account:, role:, user: }
      .transform_keys { "X-Auth-#{_1.to_s.capitalize}" }
  end

  before do
    User.current_user = User.new(userid: 'member@example.com', token: nil,
                                 account: 'test', role: 'member')
    $gateway = create(:cloud_gateway, account: 'test')
    $certificate = create_certificate(account: 'test')
    $certificate_values = $certificate.send(:values)
    $service = create(:service)
    $route = create(
      :route,
      cloud_gateway_id: $gateway.id,
      owner:            'member@example.com',
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
        service = create(:service, owner: 'member@example.com')
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Member's account + other email
        service = create(:service, owner: 'not_member@example.com')
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'not_member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Other account + member's email
        service = create(:service, owner: 'member@example.com')
        cert = create_certificate(account: 'icdc')
        route = create(
          :route,
          cloud_gateway_id: gateway_icdc.id,
          owner:            'member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])
      end

      get "/api/v1/routes",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "member@example.com"
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
        service = create(:service, owner: 'member@example.com')
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'admin@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Member's account + other email
        service = create(:service, owner: 'not_member@example.com')
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'not_member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Other account + member's email
        service = create(:service, owner: 'admin@example.com')
        cert = create_certificate(account: 'icdc')
        route = create(
          :route,
          cloud_gateway_id: gateway_icdc.id,
          owner:            'admin@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])
      end

      get "/api/v1/routes",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "admin@example.com"
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
        service = create(:service, owner: 'member@example.com')
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Member's account + other email
        service = create(:service, owner: 'not_member@example.com')
        cert = create_certificate(account: 'test')
        route = create(
          :route,
          cloud_gateway_id: gateway_test.id,
          owner:            'not_member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])

        # Other account + member's email
        service = create(:service, owner: 'member@example.com')
        cert = create_certificate(account: 'icdc')
        route = create(
          :route,
          cloud_gateway_id: gateway_icdc.id,
          owner:            'member@example.com',
          certificate_id:   cert.id
        )
        add_routes_services(route, [ { id: service.id } ])
      end

      get "/api/v1/routes",
          params:  nil,
          headers: {
            "X-Auth-Account": "location",
            "X-Auth-Role":    "operator",
            "X-Auth-User":    "operator@example.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(test_count * 3)
    end
  end

  describe "POST /api/v1/routes" do
    let(:gateway)     { create(:cloud_gateway, account:) }
    let(:service)     { create(:service, owner: user) }
    let(:certificate) { create_certificate(account:) }
    let(:services) { [ { id: service.id } ] }
    let(:params) do
      {
        'route' => attributes_for(
          :route_http,
          type:             'http',
          owner:            user,
          cloud_gateway_id: gateway.id,
          certificate_id:   certificate.id,
          services:
        )
      }.as_json
    end

    context "with 1 service in params" do
      let(:services) { [ { id: service.id } ] }

      it 'creates a new route' do
        expect { post('/api/v1/routes', params:, headers:) }
          .to change(Route, :count).by(1)
          .and change(RoutesService, :count).by(services.size)
      end

      it 'renders route as json' do
        post('/api/v1/routes', params:, headers:)

        expect(response).to have_http_status(:created)

        body = response.parsed_body
        expect(body).to eq(Route.last.as_json)
      end

      it 'creates route with passed params' do
        post('/api/v1/routes', params:, headers:)

        route_attributes = Route.last.as_json(
          except: %w[id created_at updated_at cloud_gateway healthcheck
                     services routes_services]
        ).except("middlewares")

        expect(route_attributes).to eq(
          params['route'].except('services', 'middlewares')
        )
      end

      it 'create routes_service' do
        post('/api/v1/routes', params:, headers:)

        routes_services = Route.last.routes_services
        expect(routes_services.count).to eq(services.size)
        expect(routes_services.pluck(:service_id)).to eq(services.pluck(:id))
      end
    end

    context "with more than 1 service in params" do
      let(:services) do
        create_list(:service, 2, owner: user).map do |service|
          { id: service.id, weight: 1 }
        end
      end

      it 'creates a new route' do
        expect { post('/api/v1/routes', params:, headers:) }
          .to change(Route, :count).by(1)
          .and change(RoutesService, :count).by(services.size)
      end

      it 'renders route as json' do
        post('/api/v1/routes', params:, headers:)

        expect(response).to have_http_status(:created)

        body = response.parsed_body
        expect(body).to eq(Route.last.as_json)
      end

      it 'creates route with passed params' do
        post('/api/v1/routes', params:, headers:)

        route_attributes = Route.last.as_json(
          except: %w[id created_at updated_at cloud_gateway healthcheck
                     services routes_services]
        ).except("middlewares")

        expect(route_attributes).to eq(
          params['route'].except('services', 'middlewares')
        )
      end

      it 'create routes_service' do
        post('/api/v1/routes', params:, headers:)

        routes_services = Route.last.routes_services
        expect(routes_services.count).to eq(services.size)
        expect(routes_services.pluck(:service_id, :value))
          .to eq(services.pluck(:id, :weight))
      end
    end

    context "with service in params attached to another route" do
      let(:target_port) { 3000 }
      let(:another_route) { create(:route_http, target_port:) }
      let(:port) { target_port }
      let(:params) do
        {
          'route' => attributes_for(
            :route_http,
            type:             'http',
            owner:            user,
            cloud_gateway_id: gateway.id,
            certificate_id:   certificate.id,
            services:,
            target_port:      port
          )
        }.as_json
      end

      before { create(:routes_service, service:, route: another_route) }

      context "with another target port in params" do
        let(:port) { target_port + 1 }

        it "allows to create route to another port" do
          expect { post('/api/v1/routes', params:, headers:) }
            .to change(Route, :count).by(1)
            .and change(RoutesService, :count).by(services.size)
          expect(response).to have_http_status(:created)
          expect(Route.last.routes_services.pluck(:service_id))
            .to eq(services.pluck(:id))
        end
      end

      context "with same target port in params" do
        let(:port) { target_port }

        it "does not create route" do
          expect { post('/api/v1/routes', params:, headers:) }
            .not_to change(Route, :count)
        end

        it "renders error" do
          # expect { post('/api/v1/routes', params:, headers:) }
          #   .to raise_error(ActiveRecord::RecordInvalid)
          #
          post('/api/v1/routes', params:, headers:)

          expect(response).to have_http_status(:unprocessable_content)

          expect(response.parsed_body)
            .to eq({ "code"    => "ENT025",
                     "data"    => nil,
                     "errors"  => [ "Validation failed: Route to service port already created" ],
                     "message" => "Route creation failed. Invalid data",
                     "status"  => 422 })
        end
      end
    end

    it 'valdates route name on uniqueness among gateway' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'member@example.com')
      create(
        :route,
        name:             'test_name',
        cloud_gateway_id: gateway.id,
        owner:            'member@example.com'
      )
      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'ip_version', 'insecure')
                                        .merge(
                                          'owner'           => "member@example.com",
                                          'name'            => 'test_name',
                                          :cloud_gateway_id => gateway.id,
                                          :services         => [ { id: service.id } ]
                                        ) }
      post '/api/v1/routes',
           params:  request_body,
           headers: {
             "X-Auth-Account": "test",
             "X-Auth-Role":    "member",
             "X-Auth-User":    "member@example.com"
           }
      expect(response).to have_http_status(:unprocessable_content)
    rescue ActiveRecord::RecordInvalid => error
      expect(error)
    end

    it "renders 404 if cloud_gateway does not exist" do
      create(:cloud_gateway, account: "test")
      service = create(:service, owner: 'member@example.com')
      cert = create_certificate(account: "test")

      request_body = {
        "route" => $route
                     .attributes
                     .slice("name", "hostname", "target_port",
                            "tls_termination", "owner", "path",
                            "ip_version", "insecure")
                     .merge(cloud_gateway_id: 0,
                            certificate_id:   cert.id,
                            services:         [ { id: service.id } ])
      }
      expect do
        post '/api/v1/routes',
             params:  request_body,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "member",
               "X-Auth-User":    "member@example.com"
             }
      end.not_to change(Route, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "renders 404 if cloud_gateway from another account" do
      gateway = create(:cloud_gateway, account: "not_a_test")
      service = create(:service, owner: 'member@example.com')
      cert = create_certificate(account: "not_a_test")

      request_body = {
        "route" => $route
                     .attributes
                     .slice("name", "hostname", "target_port",
                            "tls_termination", "owner", "path",
                            "ip_version", "insecure")
                     .merge(cloud_gateway_id: gateway.id,
                            certificate_id:   cert.id,
                            services:         [ { id: service.id } ])
      }
      expect do
        post '/api/v1/routes',
             params:  request_body,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "member",
               "X-Auth-User":    "member@example.com"
             }
      end.not_to change(Route, :count)
      expect(response).to have_http_status(:not_found)
    end

    context "with middlewares in params" do
      let(:middlewares) do
        [
          attributes_for(
            :middleware_http_rate_limit,
            type:    "RateLimit",
            options: {}
          )
        ]
      end
      let(:params) do
        {
          'route' => attributes_for(
            :route_http,
            type:             'http',
            owner:            user,
            cloud_gateway_id: gateway.id,
            certificate_id:   certificate.id,
            services:,
            middlewares:
          )
        }.as_json
      end

      it 'creates a new route' do
        expect { post('/api/v1/routes', params:, headers:) }
          .to change(Route, :count).by(1)
          .and change(RoutesService, :count).by(services.size)
          .and change(Middleware, :count).by(middlewares.size)
      end

      it 'renders route as json' do
        post('/api/v1/routes', params:, headers:)

        expect(response).to have_http_status(:created)

        body = response.parsed_body
        expect(body).to eq(Route.last.as_json)
      end

      it 'create middlewares' do
        post('/api/v1/routes', params:, headers:)

        route_middlewares = Route.last.as_json['middlewares']
        expect(route_middlewares.size).to eq(middlewares.size)
        expect(route_middlewares.pluck("type", "options"))
          .to eq(middlewares.pluck(:type, :options))
      end
    end
  end

  describe "GET /api/v1/routes/:id" do
    it 'shows route details' do
      gateway_test = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'member@example.com')
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway_test.id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      routes_service = add_routes_services(route, [ { id: service.id } ])

      get "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "member@example.com"
          }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['route']
             .except(*%w[created_at updated_at routes_services services
                         cloud_gateway type middlewares]))
        .to eq(route.attributes.except(
                 *%w[created_at updated_at routes_services services
                     cloud_gateway type]
               ))
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
            "X-Auth-Account": "location",
            "X-Auth-Role":    "operator",
            "X-Auth-User":    "operator@example.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t show routes from different account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      service = create(:service, owner: 'admin@example.com')
      cert = create_certificate(account: 'not_test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      get "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "admin@example.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t show not own route to member' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'not_member@example.com')
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'not_member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      get "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "member@example.com"
          }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/routes/:id" do
    let(:cloud_gateway) { create(:cloud_gateway, account:) }
    let(:certificate)   { create_certificate(account:) }
    let(:route)         { create(:route_http, owner: user, cloud_gateway:) }

    it 'updates route' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'member@example.com')
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])

      service = create(:service, owner: 'member@example.com')
      cert = create_certificate(account: 'test')

      request_body = { 'route' => $route.attributes
                                        .slice('name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
                                               'ip_version', 'insecure')
                                        .merge(
                                          cloud_gateway_id: gateway.id,
                                          certificate_id:   cert.id,
                                          services:         [ { id: service.id } ]
                                        ) }
      put "/api/v1/routes/#{route.id}",
          params:  request_body,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "member@example.com"
          }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body).to eq(route.reload.as_json)
      expect(body.slice(
               'name', 'hostname', 'target_port', 'tls_termination', 'owner', 'path',
               'ip_version', 'insecure'
             )).to eq(request_body['route'].except(
                        :cloud_gateway_id, :certificate_id, :services
                      ))
      expect(body['services'][0]).to eq(service.reload.as_json)
      expect(body['routes_services'][0]).to eq(route.routes_services.first.as_json)
    end

    it 'returns \'404\' if route doesn\'t exist' do
      put "/api/v1/routes/#{rand { 1..100 }}",
          params:  nil,
          headers: {
            "X-Auth-Account": "location",
            "X-Auth-Role":    "operator",
            "X-Auth-User":    "operator@example.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update routes from different account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      service = create(:service, owner: 'admin@example.com')
      cert = create_certificate(account: 'not_test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      put "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "admin",
            "X-Auth-User":    "admin@example.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t update not own route to member' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'not_member@example.com')
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'not_member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      put "/api/v1/routes/#{route.id}",
          params:  nil,
          headers: {
            "X-Auth-Account": "test",
            "X-Auth-Role":    "member",
            "X-Auth-User":    "member@example.com"
          }
      expect(response).to have_http_status(:not_found)
    end

    it "sets certificate_id = nil when send certificate_id = \"\"" do
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: create(:cloud_gateway, account: 'test').id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route,
                          [ { id: create(:service,
                                         owner: 'member@example.com').id } ])

      request_body = { "route" => { "certificate_id" => "" } }

      expect do
        patch "/api/v1/routes/#{route.id}",
              params:  request_body,
              headers: {
                "X-Auth-Account": "test",
                "X-Auth-Role":    "member",
                "X-Auth-User":    "member@example.com"
              }
      end.to change { route.reload.certificate_id }.from(cert.id).to(nil)
      expect(response).to have_http_status(:ok)
    end

    context "with new services in params" do
      it "updates services list"
    end

    context "with middlewares" do
      let!(:middlewares) do
        [
          create(
            :middleware_http_add_prefix,
            route:,
            options: { "prefix" => "/old_prefix" }
          ).as_json.slice("type", "options")
        ]
      end

      context "with new middlewares in params" do
        let(:new_middlewares) do
          [
            {
              "type"    => "AddPrefix",
              "options" => { "prefix" => "/new_prefix" }
            }
          ]
        end
        let(:params) do
          {
            "route" => {
              "middlewares" => new_middlewares
            }
          }.as_json
        end

        it "updates middlewares list" do
          expect { put("/api/v1/routes/#{route.id}", params:, headers:) }
            .to change {
              route.reload.as_json["middlewares"].pluck("type", "options")
            }.from(middlewares.pluck("type", "options"))
             .to(new_middlewares.pluck("type", "options"))
        end
      end

      context "with empty middlewares list in params" do
        let(:new_middlewares) { [] }
        let(:params) do
          {
            "route" => {
              "middlewares" => new_middlewares
            }
          }.as_json
        end

        it "updates middlewares list" do
          expect { put("/api/v1/routes/#{route.id}", params:, headers:) }
            .to change {
              route.reload.as_json["middlewares"].pluck("type", "options")
            }.from(middlewares.pluck("type", "options"))
             .to(new_middlewares.pluck("type", "options"))
        end
      end
    end

    context "without middlewares" do
      let!(:middlewares) { [] }

      context "with new middlewares in params" do
        let(:new_middlewares) do
          [
            {
              "type"    => "AddPrefix",
              "options" => { "prefix" => "/new_prefix" }
            }
          ]
        end
        let(:params) do
          {
            "route" => {
              "middlewares" => new_middlewares
            }
          }.as_json
        end

        it "updates middlewares list" do
          expect { put("/api/v1/routes/#{route.id}", params:, headers:) }
            .to change {
              route.reload.as_json["middlewares"].pluck("type", "options")
            }.from(middlewares.pluck("type", "options"))
             .to(new_middlewares.pluck("type", "options"))
        end
      end
    end
  end

  describe "DELETE /api/v1/routes/:id" do
    it 'deletes route' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'member@example.com')
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      delete "/api/v1/routes/#{route.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "member",
               "X-Auth-User":    "member@example.com"
             }
      expect(response).to have_http_status(:no_content)
      expect(Route.count).to eq(0)
      expect(RoutesService.count).to eq(0)
    end

    it 'returns \'404\' if route doesn\'t exist' do
      delete "/api/v1/routes/#{rand { 1..100 }}",
             params:  nil,
             headers: {
               "X-Auth-Account": "location",
               "X-Auth-Role":    "operator",
               "X-Auth-User":    "operator@example.com"
             }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t delete routes from different account' do
      gateway = create(:cloud_gateway, account: 'not_test')
      service = create(:service, owner: 'admin@example.com')
      cert = create_certificate(account: 'not_test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      delete "/api/v1/routes/#{route.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "admin",
               "X-Auth-User":    "admin@example.com"
             }
      expect(response).to have_http_status(:not_found)
    end

    it 'doesn\'t delete not own route to member' do
      gateway = create(:cloud_gateway, account: 'test')
      service = create(:service, owner: 'not_member@example.com')
      cert = create_certificate(account: 'test')
      route = create(
        :route,
        cloud_gateway_id: gateway.id,
        owner:            'not_member@example.com',
        certificate_id:   cert.id
      )
      add_routes_services(route, [ { id: service.id } ])
      delete "/api/v1/routes/#{route.id}",
             params:  nil,
             headers: {
               "X-Auth-Account": "test",
               "X-Auth-Role":    "member",
               "X-Auth-User":    "member@example.com"
             }
      expect(response).to have_http_status(:not_found)
    end
  end
end
