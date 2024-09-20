class ShipmentProcessor
  def initialize(origin_port:, destination_port:, criteria:)
    @origin_port = origin_port
    @destination_port = destination_port
    @criteria = criteria
    data = DataLoader.load_data
    @sailings = data["sailings"]
    @rates = data["rates"]
    @exchange_rates = data["exchange_rates"]
  end

  def process
    case @criteria
    when "cheapest-direct"
      find_cheapest_direct
    when "cheapest"
      find_cheapest
    when "fastest"
      find_fastest
    else
      raise "Invalid criteria"
    end
  end

  private

  def find_cheapest_direct
    cheapest_sailing = {}
    converter = CurrencyConverter.new(@exchange_rates)

    @sailings.each do |sailing|
      next unless @origin_port == sailing["origin_port"] && @destination_port == sailing["destination_port"]

      sailing_rate = find_sailing_rate(sailing["sailing_code"])
      next unless sailing_rate

      rate_in_eur = converter.convert(
        amount: sailing_rate["rate"],
        currency: sailing_rate["rate_currency"],
        date: sailing["departure_date"]
      )
      next unless rate_in_eur

      sailing_with_rate = sailing.merge(sailing_rate, "rate_in_eur" => rate_in_eur)
      if cheapest_sailing.empty? || sailing_with_rate["rate_in_eur"] < cheapest_sailing["rate_in_eur"]
        cheapest_sailing = sailing_with_rate
      end
    end

    cheapest_sailing.delete("rate_in_eur")
    cheapest_sailing
  end

  def find_cheapest
  end

  def find_fastest
  end

  def find_sailing_rate(sailing_code)
    @rates.find { |rate| rate["sailing_code"] == sailing_code }
  end
end
