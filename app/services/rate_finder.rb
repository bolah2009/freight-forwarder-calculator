class RateFinder
  def initialize(rates)
    @rates_by_code = rates.index_by { |rate| rate["sailing_code"] }
  end

  def find_rate(sailing_code)
    @rates_by_code[sailing_code]
  end
end
