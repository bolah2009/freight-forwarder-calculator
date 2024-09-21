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
    cheapest_sailing = nil
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
      if cheapest_sailing.nil? || sailing_with_rate["rate_in_eur"] < cheapest_sailing["rate_in_eur"]
        cheapest_sailing = sailing_with_rate
      end
    end

    cheapest_sailing&.delete("rate_in_eur")
    cheapest_sailing
  end

  def find_cheapest
    ports = Hash.new { |hash, key| hash[key] = { cost: Float::INFINITY, path: [], arrival_date: nil } }
    ports[@origin_port][:cost] = 0
    queue = [ @origin_port ]

    until queue.empty?
      current_port = queue.shift
      current_info = ports[current_port]
      sailings = sailings_from_current_port(current_port, current_info[:arrival_date])

      sailings.each do |sailing|
        destination_port = sailing["destination_port"]
        sailing_rate = find_sailing_rate(sailing["sailing_code"])
        next unless sailing_rate

        rate_in_eur = converter.convert(
          amount: sailing_rate["rate"],
          currency: sailing_rate["rate_currency"],
          date: sailing["departure_date"]
        )
        next unless rate_in_eur

        new_cost = current_info[:cost] + rate_in_eur
        if new_cost < ports[destination_port][:cost]
          ports[destination_port][:cost] = new_cost
          ports[destination_port][:path] = current_info[:path] + [ sailing.merge(sailing_rate) ]
          ports[destination_port][:arrival_date] = Date.parse(sailing["arrival_date"])
          # We do not want to process ports from the last destination
          queue << destination_port unless destination_port == @destination_port
        end
      end
    end

    ports[@destination_port][:path]
  end

  def find_fastest
  end

  def find_sailing_rate(sailing_code)
    @rates.find { |rate| rate["sailing_code"] == sailing_code }
  end

  def sailings_from_current_port(current_port, arrival_date)
    # We select only the sailing that:
    # 1. has the same origin_port as the current_port
    # 2. will not depart ealier than the current arrival date (if it exists)
    # 3. will not go back to the origin_port (although this is already handled where origin weight are zero)
    @sailings.select do |sailing|
      (sailing["origin_port"] == current_port) &&
      (!arrival_date || Date.parse(sailing["departure_date"]) > arrival_date)  &&
      (sailing["destination_port"] != @origin_port)
    end
  end

  def converter
    CurrencyConverter.new(@exchange_rates)
  end
end
