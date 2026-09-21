require 'rails_helper'

RSpec.describe RoutesService, :aggregate_failures do
  describe "weight validation" do
    let(:routes_service) { build(:routes_service, balance_type: :weighted) }

    [ 1, 3, "1", "100", nil ].each do |weight|
      it "is valid with #{weight.inspect}" do
        routes_service.value = weight
        expect(routes_service).to be_valid
      end
    end

    [ 0, -1, 2.5, 3.0, "2.5", "abc", "" ].each do |weight|
      it "is invalid with #{weight.inspect}" do
        routes_service.value = weight
        expect(routes_service).not_to be_valid
        expect(routes_service.errors[:weight]).to be_present
      end
    end

    it "does not validate loadbalancer value" do
      routes_service.balance_type = :loadbalancer
      routes_service.value = 2.5
      expect(routes_service).to be_valid
    end

    it "does not break existing records with float weight" do
      routes_service.value = 3
      routes_service.save!
      routes_service.reload.name = "renamed"
      expect(routes_service).to be_valid
    end
  end
end
