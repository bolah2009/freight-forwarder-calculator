class ShipmentProcessor
  def initialize(origin_port:, destination_port:, criteria:)
    @origin_port = origin_port
    @destination_port = destination_port
    @criteria = criteria
    @data = DataLoader.load_data
    @sailings = @data["sailings"]
    @exchange_rates = @data["exchange_rates"]
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
    cheapest_direct = {}
    @sailings.each do |sailing|
      next unless @origin_port == sailing["origin_port"] && @destination_port == sailing["destination_port"]

      sailing_rate = find_sailing_rate(sailing["sailing_code"])
      next cheapest_direct = sailing.merge(sailing_rate) if cheapest_direct.empty?

      if sailing_rate["rate_currency"] == "EUR"
        if cheapest_direct["rate"] > sailing_rate["rate"]
          cheapest_direct = sailing.merge(sailing_rate)
        end
      else
        exchange_rate = find_exchange_rates(sailing["departure_date"])
        rate_in_eur = convert_rates(sailing_rate, exchange_rate)

        if cheapest_direct["rate"] > rate_in_eur
          cheapest_direct = sailing.merge(sailing_rate)
        end
      end
    end

    cheapest_direct
  end



  def find_cheapest
  end

  def find_fastest
  end

  def find_sailing_rate(sailing_code)
    @data["rates"].find { |rate| rate["sailing_code"] == sailing_code }
  end

  def find_exchange_rates(date)
    @data["exchange_rates"][date]
  end

  def convert_rates(sailing_rate, exchange_rate)
    rate = sailing_rate["rate"]
    rate_currency = sailing_rate["rate_currency"].downcase
    rate / exchange_rate[rate_currency]
  end
end
