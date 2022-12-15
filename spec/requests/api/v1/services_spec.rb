require 'rails_helper'
require 'swagger_helper'
require './spec/factories/certificate_helper.rb'

describe 'Api::V1::ServicesController', type: :request do
  path "/api/v1/services" do
    get "Show all services" do
      tags "Services"

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

        it "shows all member\'s services" do |example|
          test_count = rand(1..20)
          test_count.times do
            FactoryBot.create(:service, :account => 'test', :owner => 'test_member@test.com')
            FactoryBot.create(:service, :account => 'test', :owner => 'not_test_member@test.com')
            FactoryBot.create(:service, :account => 'not_test', :owner => 'test_member@test.com')
          end
          get "/api/v1/services",
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

        it "shows all account\'s services" do |example|
          test_count = rand(1..20)
          test_count.times do
            FactoryBot.create(:service, :account => 'test', :owner => 'not_test_admin@test.com')
            FactoryBot.create(:service, :account => 'test', :owner => 'test_admin@test.com')
            FactoryBot.create(:service, :account => 'not_test', :owner => 'test_admin@test.com')
          end
          get "/api/v1/services",
            :params => nil,
            :headers => {
              :'x-icdc-account' => 'test',
              :'x-icdc-role' => 'admin',
              :Authorization => JWT_ADMIN
            }
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).size).to eq(test_count * 2)
        end

        it "shows all services" do |example|
          test_count = rand(1..20)
          test_count.times do
            FactoryBot.create(:service, :account => 'test', :owner => 'test_location_admin@test.com')
            FactoryBot.create(:service, :account => 'test', :owner => 'not_test_member@test.com')
            FactoryBot.create(:service, :account => 'not_test', :owner => 'test_location_admin@test.com')
          end
          get "/api/v1/services",
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
  end
end
