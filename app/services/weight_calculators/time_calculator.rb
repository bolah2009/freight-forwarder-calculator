module WeightCalculators
  class TimeCalculator < BaseCalculator
    def calculate(sailing, _rate)
      (Date.parse(sailing["arrival_date"]) - Date.parse(sailing["departure_date"])).to_i
    end
  end
end
