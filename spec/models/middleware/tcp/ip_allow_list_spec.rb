require 'rails_helper'

RSpec.describe Middleware::Tcp::IpAllowList, :aggregate_failures do
  let(:route) { create(:route_tcp) }
  let(:valid_attributes) do
    {
      # type:    "Middleware::Tcp::IpAllowList",
      route:,
      options: {
        "sourceRange" => "127.0.0.1/32,192.168.1.7"
      }
    }
  end
  let(:middleware) { described_class.new(valid_attributes) }

  it "is valid with valid attributes" do
    expect(middleware).to be_valid
    expect(create(:middleware_tcp_ip_allow_list)).to be_valid
  end
end
