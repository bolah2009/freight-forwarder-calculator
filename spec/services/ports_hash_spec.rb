require "rails_helper"

RSpec.describe PortsHash do
  subject(:ports_hash) { described_class.new }

  let(:port) { ports_hash[port_code] }

  describe "#[]" do
    context "when accessing a new port" do
      let(:port_code) { "ABC" }

      it "returns a default port hash" do
        expect(port).to eq(weight: Float::INFINITY, path: [], arrival_date: nil, stops: 0)
      end
    end

    context "when accessing an existing port" do
      let(:port_code) { "DEF" }
      let(:existing_port) { { weight: 100, path: ["some_path"], arrival_date: Time.zone.today, stops: 1 } }

      before do
        ports_hash.instance_variable_get(:@ports)[port_code] = existing_port
      end

      it "returns the existing port hash" do
        expect(port).to eq(existing_port)
      end
    end
  end
end
