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
        burst:   200,
        redis:   {
          endpoints:      [
            "redis-primary.example.com:6379",
            "redis-replica.example.com:6379"
          ],
          username:       "ratelimit-user",
          password:       "secure-password",
          db:             2,
          poolSize:       50,
          minIdleConns:   10,
          maxActiveConns: 200,
          readTimeout:    "3s",
          writeTimeout:   '3s',
          dialTimeout:    '5s',
          tls:            {
            ca:                 "/etc/ssl/redis-ca.crt",
            cert:               "/etc/ssl/redis-client.crt",
            key:                "/etc/ssl/redis-client.key",
            insecureSkipVerify: false
          }
        }
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
        :middleware_http_rate_limit,
        options: {
          # int:
          "average"                      => "100",
          # float
          "burst"                        => "200.5",
          # string
          "period"                       => "1s",
          # hash, array
          "redis.endpoints"              => "redis-primary.example.com:6379," \
                                            "redis-replica.example.com:6379",
          # boolean
          "redis.tls.insecureSkipVerify" => "false"
        }
      )
    end
    let(:expected_options) do
      {
        "average"                      => Integer,
        "burst"                        => Float,
        "period"                       => String,
        "redis"                        => Hash,
        "redis.endpoints"              => Array,
        "redis.tls.insecureSkipVerify" => FalseClass # boolean
        # Nil, null
      }
    end

    it "saves options with right data types" do
      expected_options.each do |key, value|
        expect(middleware.options.dig(*key.split('.'))).to be_a value
      end
    end
  end

  describe '#as_json' do
    let(:middleware) do
      create(
        :middleware_http_rate_limit,
        options: {
          average: 100,
          period:  "1s",
          burst:   200,
          redis:   {
            endpoints:      [
              "redis-primary.example.com:6379",
              "redis-replica.example.com:6379"
            ],
            username:       "ratelimit-user",
            password:       "secure-password",
            db:             2,
            poolSize:       50,
            minIdleConns:   10,
            maxActiveConns: 200,
            readTimeout:    "3s",
            writeTimeout:   '3s',
            dialTimeout:    '5s',
            tls:            {
              ca:                 "/etc/ssl/redis-ca.crt",
              cert:               "/etc/ssl/redis-client.crt",
              key:                "/etc/ssl/redis-client.key",
              insecureSkipVerify: false
            }
          }
        }
      )
    end
    let(:expected) do
      {
        "id"         => middleware.id,
        "type"       => "RateLimit",
        "route_id"   => middleware.route_id,
        "options"    => {
          "average"                      => "100",
          "period"                       => "1s",
          "burst"                        => "200",
          "redis.endpoints"              => "redis-primary.example.com:6379," \
                                            "redis-replica.example.com:6379",
          "redis.username"               => "ratelimit-user",
          "redis.password"               => "secure-password",
          "redis.db"                     => "2",
          "redis.poolSize"               => "50",
          "redis.minIdleConns"           => "10",
          "redis.maxActiveConns"         => "200",
          "redis.readTimeout"            => "3s",
          "redis.writeTimeout"           => "3s",
          "redis.dialTimeout"            => "5s",
          "redis.tls.ca"                 => "/etc/ssl/redis-ca.crt",
          "redis.tls.cert"               => "/etc/ssl/redis-client.crt",
          "redis.tls.key"                => "/etc/ssl/redis-client.key",
          "redis.tls.insecureSkipVerify" => "false"
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

  describe "Options vaidation" do
    let(:middleware) { create(:middleware_http_rate_limit) }

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
      middleware.options = { "average" => "100" }
      expect(middleware).to be_valid
      middleware.options = { "average" => "string" }
      expect(middleware).not_to be_valid
    end

    it "validates time interval value type" do
      middleware.options = { "period" => "1s" }
      expect(middleware).to be_valid
      middleware.options = { "period" => "string" }
      expect(middleware).not_to be_valid
    end

    it "validates boolean value type" do
      middleware.options = { "redis.tls.insecureSkipVerify" => "false" }
      expect(middleware).to be_valid
      middleware.options = { "redis.tls.insecureSkipVerify" => "true" }
      expect(middleware).to be_valid
      middleware.options = { "redis.tls.insecureSkipVerify" => "string" }
      expect(middleware).not_to be_valid
    end
  end
end
