class ShipmentProcessor
  def initialize(origin_port:, destination_port:, criteria:, max_stops: Float::INFINITY)
    @origin_port = origin_port
    @destination_port = destination_port
    @criteria = criteria
    @max_stops = max_stops
  end

  def process
    data = DataLoader.fetch
    sailings_by_origin = data["sailings"].group_by { |sailing| sailing["origin_port"] }
    rates = data["rates"]
    exchange_rates = data["exchange_rates"]

    rate_finder = RateFinder.new(rates)
    currency_converter = CurrencyConverter.new(exchange_rates)
    weight_calculator = select_weight_calculator(currency_converter)

    route_finder = RouteFinder.new(sailings_by_origin, weight_calculator, rate_finder, @max_stops)
    route_finder.find_route(@origin_port, @destination_port)
  end

  private

  def select_weight_calculator(currency_converter)
    case @criteria
    when "cheapest-direct"
      @max_stops = 0
      WeightCalculators::CostCalculator.new(currency_converter)
    when "cheapest"
      WeightCalculators::CostCalculator.new(currency_converter)
    when "fastest"
      WeightCalculators::TimeCalculator.new
    else
      raise "Invalid criteria"
    end
  end
end
