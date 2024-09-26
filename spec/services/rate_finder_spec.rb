require "rails_helper"

RSpec.describe RateFinder do
  subject(:rate_finder) { described_class.new(rates) }

  let(:rates) do
    [
      { "sailing_code" => "SC1", "rate" => "100", "rate_currency" => "USD" },
      { "sailing_code" => "SC2", "rate" => "200", "rate_currency" => "EUR" }
    ]
  end

  describe "#initialize" do
    let(:expected_result) do
      {
        "SC1" => { "sailing_code" => "SC1",
                   "rate" => "100", "rate_currency" => "USD" },
        "SC2" => { "sailing_code" => "SC2",
                   "rate" => "200", "rate_currency" => "EUR" }
      }
    end

    it "indexes rates by sailing_code" do
      expect(rate_finder.instance_variable_get(:@rates_by_code)).to eq(expected_result)
    end
  end

  describe "#find_rate" do
    let(:rate) { rate_finder.find_rate(sailing_code) }

    context "when the sailing code exists" do
      let(:sailing_code) { "SC1" }

      it "returns the correct rate" do
        expect(rate).to eq("sailing_code" => "SC1", "rate" => "100", "rate_currency" => "USD")
      end
    end

    context "when the sailing code does not exist" do
      let(:sailing_code) { "SC3" }

      it "returns nil" do
        expect(rate).to be_nil
      end
    end
  end
end
