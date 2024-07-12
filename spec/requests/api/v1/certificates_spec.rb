require 'rails_helper'
require 'swagger_helper'
require './spec/factories/certificate_helper.rb'

describe 'Api::V1::CertificatesController', type: :request do
  path "/api/v1/certificates" do
    get "Show all certificates" do
      tags "Certificates"

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

        it 'shows all member\'s certificates' do |example|
          FactoryBot.create(:cloud_gateway, :account => 'test')
          FactoryBot.create(:cloud_gateway, :account => 'icdc')
          test_count = rand(5) + 1
          test_count.times do
            create_certificate(:account => 'test')
            create_certificate(:account => 'test', :owner => "not_test_member@test.com")
            create_certificate(:account => 'icdc')
          end

          get "/api/v1/certificates",
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

        it 'shows all certificates (to location admin)' do |example|
          FactoryBot.create(:cloud_gateway, :account => 'test')
          FactoryBot.create(:cloud_gateway, :account => 'icdc')
          test_count = rand(5) + 1
          test_count.times do
            create_certificate(:account => 'test')
            create_certificate(:account => 'icdc')
          end
          get "/api/v1/certificates",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'location',
              :'x-icdc-role' => 'operator',
              :Authorization => JWT_LOCATION_OPERATOR
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count * 2)
        end

        it 'shows all account\'s certificates' do |example|
          FactoryBot.create(:cloud_gateway, :account => 'test')
          FactoryBot.create(:cloud_gateway, :account => 'icdc')
          test_count = rand(5) + 1
          test_count.times do
            create_certificate(:account => 'test')
            create_certificate(:account => 'test', :owner => "not_test_member@test.com")
            create_certificate(:account => 'icdc')
          end

          get "/api/v1/certificates",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count * 2)
        end
      end
    end

    post "Create a new certificate" do
      tags "Certificates"

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
            'certificate' => { type: :object,
              'properties' => {
                name:    { :$ref => '#/components/schemas/certificate/properties/name' },
                cert:    { :$ref => '#/components/schemas/certificate/properties/values/properties/cert' },
                key:     { :$ref => '#/components/schemas/certificate/properties/values/properties/key' },
                ca:      { :$ref => '#/components/schemas/certificate/properties/values/properties/ca' },
                dest_ca: { :$ref => '#/components/schemas/certificate/properties/values/properties/dest_ca' },
                owner:   { :$ref => '#/components/schemas/certificate/properties/owner' }
              }
            }
          }
        }

      response(
        "201",
        "Operation successfull"
      ) do

        it 'creates a new Certificate' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          request_body = {
            'certificate' => {
              'name' => "alb.computedev.zby.icdc.io",
              'owner' => "test_member@test.com"
            }.merge($certificate_values.stringify_keys.slice('cert', 'key', 'ca', 'dest_ca'))
          }
          post '/api/v1/certificates',
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:created)
          expect(Certificate.count).to eq(1)
          response_body = JSON.parse(response.body, symbolize_names: true)
          path = "#{gateway.account}/#{request_body['certificate']['name']}/"
          expect(response_body.except(:created_at, :updated_at, :id, :values)).to eq(
            request_body['certificate'].symbolize_keys.except(:cert, :key, :ca, :dest_ca).merge(
              :account => 'test',
              :ca_path => path + "ca",
              :cert_path => path + "cert",
              :dest_ca_path => path + "dest_ca",
              :key_path => path + "key"
            )
          )
          expect(response_body[:values]).to eq(
            request_body['certificate'].symbolize_keys.slice(:cert, :key, :ca, :dest_ca).merge(
              $certificate_values.symbolize_keys,
              :valid_from => "2021-03-30T16:52:40.000Z",
              :valid_until => "2021-06-28T16:52:40.000Z"
            )
          )
          generate_docs(example, response)
        end
      end
    end
  end

  path "/api/v1/certificates/{id}" do
    get "Show certificate record" do
      tags "Certificates"

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

        it 'shows certificate details' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'test_member@test.com')
          set_request_param(example, :id, certificate.id)
          get "/api/v1/certificates/#{certificate.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).except('created_at', 'updated_at', 'values')).to eq(
            certificate.attributes.except('created_at', 'updated_at', 'values'))
          expect(JSON.parse(response.body)['values']).to eq(
            certificate.send(:values).stringify_keys.merge(
              'valid_from' => "2021-03-30T16:52:40.000Z",
              'valid_until' => "2021-06-28T16:52:40.000Z"
            )
          )
          generate_docs(example, response)
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if certificate doesn\'t exist' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          get "/api/v1/certificates/#{rand(1..100)}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'doesn\'t show certificate from different account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          certificate = create_certificate(:account => 'not_test', :owner => 'test_member@test.com')
          get "/api/v1/certificates/#{certificate.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'doesn\'t show not own certificate to member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'not_test_member@test.com')
          get "/api/v1/certificates/#{certificate.id}",
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

    put "Update certificate" do
      tags "Certificates"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_ADMIN }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }
      parameter name: :request_body, in: :body, required: true,
        schema: {
          type: :object,
          properties: {
            'certificate' => { type: :object,
              'properties' => {
                name:    { type: :string, example: 'new-lb.computedev.zby.icdc.io' },
                cert:    { type: :string, example: $certificate_values[:cert] },
                key:     { type: :string, example: $certificate_values[:key] },
                ca:      { type: :string, example: $certificate_values[:ca] },
                dest_ca: { type: :string, example: $certificate_values[:dest_ca] },
                owner:   { type: :string, example: 'new_user@test.com' }
              }
            }
          }
        }

      response(
        "200",
        "Operation successfull"
      ) do

        it 'updates certificate' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test')
          set_request_param(example, :id, certificate.id)
          request_body = {
            'certificate' => {
              'name' => "new-lb.computedev.zby.icdc.io",
            }.merge($certificate_values.stringify_keys.slice('cert', 'key', 'ca', 'dest_ca'))
          }
          put "/api/v1/certificates/#{certificate.id}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:ok)
          response_body = JSON.parse(response.body, symbolize_names: true)
          path = "#{gateway.account}/#{request_body['certificate']['name']}/"
          expect(response_body.except(:created_at, :updated_at, :id, :values)).to eq(
            request_body['certificate'].symbolize_keys.
              except(:cert, :key, :ca, :dest_ca).
              merge(
                :account => 'test',
                :owner => 'test_member@test.com',
                :ca_path => path + "ca",
                :cert_path => path + "cert",
                :dest_ca_path => path + "dest_ca",
                :key_path => path + "key"
            )
          )
          expect(response_body[:values]).to eq(
            request_body['certificate'].symbolize_keys.slice(:cert, :key, :ca, :dest_ca).merge(
              $certificate_values.symbolize_keys,
              :valid_from => "2021-03-30T16:52:40.000Z",
              :valid_until => "2021-06-28T16:52:40.000Z"
            )
          )
          generate_docs(example, response)
        end

        it 'updates certificate (Member)' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'test_member@test.com')
          request_body = {
            'certificate' => {
              'name' => "new-lb.computedev.zby.icdc.io",
            }.merge($certificate_values.stringify_keys.slice('cert', 'key', 'ca', 'dest_ca'))
          }
          put "/api/v1/certificates/#{certificate.id}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:ok)
          response_body = JSON.parse(response.body, symbolize_names: true)
          path = "#{gateway.account}/#{request_body['certificate']['name']}/"
          expect(response_body.except(:created_at, :updated_at, :id, :values)).to eq(
            request_body['certificate'].symbolize_keys.except(:cert, :key, :ca, :dest_ca).merge(
              :account => 'test',
              :owner => 'test_member@test.com',
              :ca_path => path + "ca",
              :cert_path => path + "cert",
              :dest_ca_path => path + "dest_ca",
              :key_path => path + "key"
            )
          )
          expect(response_body[:values]).to eq(
            request_body['certificate'].symbolize_keys.slice(:cert, :key, :ca, :dest_ca).merge(
              $certificate_values.symbolize_keys,
              :valid_from => "2021-03-30T16:52:40.000Z",
              :valid_until => "2021-06-28T16:52:40.000Z"
            )
          )
        end


      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if certificate doesn\'t exist' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          request_body = {
            'certificate' => {
              'name' => "new-lb.computedev.zby.icdc.io",
            }.merge($certificate_values.stringify_keys.slice('cert', 'key', 'ca', 'dest_ca'))
          }
          put "/api/v1/certificates/#{rand(1..100)}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'doesn\'t update certificate from different account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          certificate = create_certificate(:account => 'not_test', :owner => 'test_admin@test.com')
          request_body = {
            'certificate' => {
              'name' => "new-lb.computedev.zby.icdc.io",
            }.merge($certificate_values.stringify_keys.slice('cert', 'key', 'ca', 'dest_ca'))
          }
          put "/api/v1/certificates/#{certificate.id}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'doesn\'t update not own certificate for member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'not_test_member@test.com')
          request_body = {
            'certificate' => {
              'name' => "new-lb.computedev.zby.icdc.io",
            }.merge($certificate_values.stringify_keys.slice('cert', 'key', 'ca', 'dest_ca'))
          }
          put "/api/v1/certificates/#{certificate.id}",
            :params => request_body,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    delete "Delete certificate" do
      tags "Certificates"

      consumes "application/json"
      parameter name: 'x-icdc-account', description: "Name of account",
        in: :header, required: true, schema: { type: :string, example: "test" }
      parameter name: 'x-icdc-role', description: "Role of account",
        in: :header, required: true, schema: { type: :string, example: "admin" }
      parameter name: :Authorization, in: :header, required: true,
        schema: { type: :string, example: JWT_ADMIN }
      parameter name: :id, in: :path, required: true,
        schema: { type: :integer, example: 3 }

      response(
        "204",
        "Operation successfull"
      ) do

        it 'deletes certificate' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'test_admin@test.com')
          set_request_param(example, :id, certificate.id)
          delete "/api/v1/certificates/#{certificate.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:no_content)
          expect(Certificate.count).to eq(0)
          generate_docs(example, response)
        end

        it 'deletes certificate' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'test_member@test.com')
          delete "/api/v1/certificates/#{certificate.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'member',
              :Authorization => JWT_MEMBER
            }
          expect(response).to have_http_status(:no_content)
          expect(Certificate.count).to eq(0)
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if certificate doesn\'t exist' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          delete "/api/v1/certificates/#{rand(1..100)}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response)
        end

        it 'doesn\'t update certificate from different account' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'not_test')
          certificate = create_certificate(:account => 'not_test', :owner => 'test_admin@test.com')
          delete "/api/v1/certificates/#{certificate.id}",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:not_found)
        end

        it 'doesn\'t update not own certificate for member' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          certificate = create_certificate(:account => 'test', :owner => 'not_test_member@test.com')
          delete "/api/v1/certificates/#{certificate.id}",
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

  path "api/v1/cert-download/{uuid}" do
    get "Download certificate" do
      tags "Certificates"

      consumes "application/json"
      parameter name: :uuid, in: :path, required: true,
        schema: { type: :string, example: "a843bf2a-7353-563e-a220-f59949849dba" }

      response(
        "200",
        "Operation successfull"
      ) do

        it 'returns certificate' do |example|
          gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
          Sidekiq::Testing.inline! do
            certificate = create_certificate
          end
          set_request_param(example, :uuid, gateway.cloudgw_id)
          get "/api/v1/cert-download/#{gateway.cloudgw_id}"
          expect(response).to have_http_status(:ok)
          expect(response["Content-Type"]).to eq("application/zip")
          generate_docs(example, response, 'application/zip')
        end
      end

      response(
        "404",
        "Not found"
      ) do

        it 'returns \'404\' if gateway doesn\'t exists' do |example|
          get "/api/v1/cert-download/#{rand(1..1000000)}"
          expect(response).to have_http_status(:not_found)
          generate_docs(example, response, 'application/json')
        end
      end
    end
  end
end
