# frozen_string_literal: true

require 'rails_helper'
require './spec/factories/certificate_helper.rb'

def example_from_response(response)
  properties = {}
  a = response
  a.keys.each do |key|
    properties[key] = { :type => :"#{a[key].class.to_s.downcase}", :example => a[key] }
  end
  properties
end

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  
  User.current_user = User.new(userid: 'test_member@test.com', token: nil, account: 'test', role: 'member')
  $gateway = FactoryBot.create(:cloud_gateway, :account => 'test')
  $certificate = create_certificate(:account => 'test')
  $certificate_values = $certificate.send(:values)
  $service = FactoryBot.create(:service)
  $route = FactoryBot.create(
    :route,
    :cloud_gateway_id => $gateway.id,
    :owner => 'test_member@test.com',
    :certificate_id => $certificate.id
  )
  $routes_service = FactoryBot.create(:routes_service, :route => $route, :service => $service).destroy!
  $route.destroy!
  $service.destroy!
  $certificate.destroy!
  $gateway.destroy!

  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'ICDC Traefik Manager API',
        version: '1.1',
        description: 'Traefik Manager provide multi-tenant Traefik HTTP provider API to pull dynamic
                      configuration by traefik loadbalancers installed in Account\'s CloudGWs.',
        contact: { email: 'compute@icdc.io' },
        license: {
          name: 'Apache 2.0',
          url: 'http://www.apache.org/licenses/LICENSE-2.0.html'
        }
      },
      tags: [
        { name: 'Gateways', description: 'Gateways management' },
        { name: 'Certificates', description: 'Basic info about db certificates' },
        { name: 'Routes', description: 'Routes' },
        { name: 'Services', description: 'Compute Services' }
      ],
      paths: {},
#      servers: [
#        {
#          url: 'https://{defaultHost}',
#          variables: {
#            defaultHost: {
#              default: 'example.com'
#            }
#          }
#        }
#      ],
      components: {
        schemas: {
          gateway: {
            type: :object,
            properties: example_from_response($gateway.attributes.merge('id' => rand(1..10)))
          },
          certificate: {
            type: :object,
            properties: example_from_response($certificate.attributes.except('values')).merge(
              values: {
                type: :object,
                properties: example_from_response($certificate_values)
              }
            )
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml

end

def generate_docs(example, response, type = nil)
  data_type = type || (
    example.metadata[:operation] &&
    example.metadata[:operation][:produces] &&
    example.metadata[:operation][:produces][0]
  ) || 'application/json'
  case data_type
  when 'application/json'
    example.metadata[:response][:content] = {
      'application/json' => {
        example: JSON.parse(response.body, symbolize_names: true)
      }
    }
  when 'application/zip'
    example.metadata[:response][:content] = {
      data_type => {
        type: :string,
        format: :binary,
        example: response.body.bytes.pack("U*")
      }
    }
  else
    example.metadata[:response][:content] = {
      data_type => {
        example: response.body
      }
    }
  end
end

def get_request_body(example, param_name = :request_body)
  request_body = {}
  example.metadata[:operation][:parameters].
    select{|param| param[:name] == param_name}[0][:schema][:properties].
    each do |key, value|
      request_body.merge!({key => value[:example]})
    end
  request_body
end

def set_request_param(example, key, value)
  example.metadata[:operation][:parameters].
    select{|param| param[:name] == key}[0][:schema][:example] = value
end
