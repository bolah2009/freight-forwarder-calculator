require "rails_helper"

RSpec.describe WeightCalculators::TimeCalculator do
  subject(:calculator) { described_class.new }

  describe "#calculate" do
    let(:departure_date) { "2021-01-01" }
    let(:arrival_date) { "2021-01-05" }
    let(:sailing) { { "departure_date" => departure_date, "arrival_date" => "2021-01-05" } }
    let(:result) { calculator.calculate(sailing, nil) }

    it "calculates the time difference in days" do
      expect(result).to eq(4)
    end

    context "when date is nil" do
      let(:departure_date) { nil }

      it "calculates the time difference in days" do
        expect { result }.to raise_error(RuntimeError, "Invalid date input")
      end
    end

    context "when date is invalid" do
      let(:departure_date) { "invalid_date" }

      it "calculates the time difference in days" do
        expect { result }.to raise_error(RuntimeError, "Invalid date input")
      end
    end
  end
end
