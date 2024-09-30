module WeightCalculators
  class CostCalculator < BaseCalculator
    def initialize(currency_converter)
      @currency_converter = currency_converter
    end

    def calculate(sailing, rate)
      @currency_converter.convert(
        amount: rate["rate"],
        currency: rate["rate_currency"],
        date: sailing["departure_date"]
      )
    end
  end
end
