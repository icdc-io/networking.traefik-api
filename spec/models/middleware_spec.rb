require 'rails_helper'

RSpec.describe Middleware, :aggregate_failures do
  let(:route) { create(:route) }
  let(:valid_attributes) do
    {
      type:    "Middleware::Http::RateLimit",
      route:,
      options: {
        average: 100,
        period:  "1s",
        burst:   200
        # redis:   {
        #   endpoints:      [
        #     "redis-primary.example.com:6379",
        #     "redis-replica.example.com:6379"
        #   ],
        #   username:       "ratelimit-user",
        #   password:       "secure-password",
        #   db:             2,
        #   poolSize:       50,
        #   minIdleConns:   10,
        #   maxActiveConns: 200,
        #   readTimeout:    "3s",
        #   writeTimeout:   '3s',
        #   dialTimeout:    '5s',
        #   tls:            {
        #     ca:                 "/etc/ssl/redis-ca.crt",
        #     cert:               "/etc/ssl/redis-client.crt",
        #     key:                "/etc/ssl/redis-client.key",
        #     insecureSkipVerify: false
        #   }
        # }
      }
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware)).to be_valid
  end

  it "validates http route type" do
    route = create(:route_tcp)
    mw = described_class.new(
      type:    "Middleware::Http::RedirectScheme",
      route:,
      options: { "scheme" => "https" }
    )
    expect(mw).not_to be_valid

    mw.route = create(:route_http)
    expect(mw).to be_valid
  end

  it "validates tcp route type" do
    route = create(:route_http)
    mw = described_class.new(
      type:    "Middleware::Tcp::IpAllowList",
      route:,
      options: { "sourceRange" => "127.0.0.1/32" }
    )
    expect(mw).not_to be_valid

    mw.route = create(:route_tcp)
    expect(mw).to be_valid
  end

  describe "before_save" do
    let(:middleware) do
      create(
        :middleware_http_headers,
        options: {
          # int:
          "accessControlMaxAge"           => "100",
          # float
          "stsSeconds"                    => "100.5",
          # string
          "customFrameOptionsValue"       => "test",
          # hash
          "customRequestHeaders"          => "X-Script-Name=test," \
                                             "X-Custom-Request-Header=",
          # array
          "accessControlAllowMethods"     => "GET,OPTIONS,PUT",
          # boolean
          "accessControlAllowCredentials" => "true",
          "addVaryHeader"                 => "false"
        }
      )
    end
    let(:expected_options) do
      {
        "accessControlMaxAge"           => Integer,
        "stsSeconds"                    => Float,
        "customFrameOptionsValue"       => String,
        "customRequestHeaders"          => Hash,
        "accessControlAllowMethods"     => Array,
        "accessControlAllowCredentials" => TrueClass,
        "addVaryHeader"                 => FalseClass
      }
    end

    it "saves options with right data types" do
      expected_options.each do |key, value|
        expect(middleware.options.dig(*key.split('.'))).to be_a value
      end
    end
  end

  describe '#as_json' do
    context "with Headers middleware" do
      let(:middleware) do
        create(
          :middleware_http_headers,
          options: {
            accessControlMaxAge:           100,
            stsSeconds:                    100.5,
            customFrameOptionsValue:       "test",
            customRequestHeaders:          {
              "X-Script-Name":           "test",
              "X-Custom-Request-Header": ""
            },
            accessControlAllowMethods:     %w[GET OPTIONS PUT],
            accessControlAllowCredentials: true,
            addVaryHeader:                 false
          }
        )
      end
      let(:expected) do
        {
          "id"         => middleware.id,
          "type"       => "Headers",
          "route_id"   => middleware.route_id,
          "options"    => {
            "accessControlMaxAge"           => "100",
            "stsSeconds"                    => "100.5",
            "customFrameOptionsValue"       => "test",
            "customRequestHeaders"          => "X-Script-Name=test," \
                                               "X-Custom-Request-Header=",
            "accessControlAllowMethods"     => "GET,OPTIONS,PUT",
            "accessControlAllowCredentials" => "true",
            "addVaryHeader"                 => "false"
          },
          "created_at" => middleware.created_at.as_json,
          "updated_at" => middleware.updated_at.as_json
        }
      end

      before { create(:routes_service, route: middleware.route) }

      it "returns json with option lines (nested keys are joined with dots)" do
        expect(middleware.as_json).to eq(expected)
      end
    end

    context "with IpAllowList middleware" do
      let(:middleware) do
        create(
          :middleware_http_ip_allow_list,
          options: {
            sourceRange: [
              "127.0.0.1/32",
              "192.168.1.7"
            ],
            ipStrategy:  {
              depth:       0,
              excludedIPs: [
                "12.0.0.1",
                "13.0.0.1"
              ]
            }
          }
        )
      end
      let(:expected) do
        {
          "id"         => middleware.id,
          "type"       => "IpAllowList",
          "route_id"   => middleware.route_id,
          "options"    => {
            "sourceRange"            => "127.0.0.1/32,192.168.1.7",
            "ipStrategy.depth"       => "0",
            "ipStrategy.excludedIPs" => "12.0.0.1,13.0.0.1"
          },
          "created_at" => middleware.created_at.as_json,
          "updated_at" => middleware.updated_at.as_json
        }
      end

      before { create(:routes_service, route: middleware.route) }

      it "returns json with option lines (nested keys are joined with dots)" do
        expect(middleware.as_json).to eq(expected)
      end
    end
  end

  describe "Options vaidation" do
    let(:middleware) { create(:middleware_http_headers) }

    it "validates keys list" do
      middleware.options = { "invalid_key" => "invalid_value" }
      expect(middleware).not_to be_valid
    end

    it "validates required keys" do
      middleware = create(:middleware_http_add_prefix)
      expect(middleware).to be_valid
      middleware.options = {}
      expect(middleware).not_to be_valid
      middleware.options = { "prefix" => "" }
      expect(middleware).not_to be_valid
    end

    it "validates integer value type" do
      middleware.options = { "accessControlMaxAge" => "100" }
      expect(middleware).to be_valid
      middleware.options = { "accessControlMaxAge" => "string" }
      expect(middleware).not_to be_valid
    end

    it "validates time interval value type" do
      middleware = create(:middleware_http_rate_limit)
      middleware.options = { "period" => "1s" }
      expect(middleware).to be_valid
      middleware.options = { "period" => "string" }
      expect(middleware).not_to be_valid
    end

    it "validates boolean value type" do
      middleware.options = { "accessControlAllowCredentials" => "false" }
      expect(middleware).to be_valid
      middleware.options = { "accessControlAllowCredentials" => "true" }
      expect(middleware).to be_valid
      middleware.options = { "accessControlAllowCredentials" => "string" }
      expect(middleware).not_to be_valid
    end
  end
end
