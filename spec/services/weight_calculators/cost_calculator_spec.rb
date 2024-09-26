require "rails_helper"

RSpec.describe WeightCalculators::CostCalculator do
  subject(:calculator) { described_class.new(currency_converter) }

  let(:currency_converter) { instance_double(CurrencyConverter) }

  describe "#calculate" do
    let(:sailing) { { "departure_date" => "2021-01-01" } }
    let(:result) { calculator.calculate(sailing, rate) }
    let(:rate) { { "rate" => "100", "rate_currency" => "USD" } }
    let(:converted_amount) { 85.0 }

    before do
      allow(currency_converter).to receive(:convert).with(
        amount: "100",
        currency: "USD",
        date: "2021-01-01"
      ).and_return(converted_amount)
    end

    it "converts the amount" do
      expect(result).to eq(converted_amount)
    end

    it "calculates the cost using the currency converter" do
      result
      expect(currency_converter).to have_received(:convert).with(
        amount: "100", currency: "USD", date: "2021-01-01"
      )
    end
  end
end
