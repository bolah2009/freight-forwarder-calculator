require "rails_helper"

RSpec.describe WeightCalculators::BaseCalculator do
  subject(:calculator) { described_class.new }

  describe "#calculate" do
    it "raises NotImplementedError" do
      expect do
        calculator.calculate(nil)
      end.to raise_error(NotImplementedError, "Subclasses must implement the calculate method")
    end
  end
end
