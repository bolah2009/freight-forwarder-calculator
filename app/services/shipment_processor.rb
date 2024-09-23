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
      find_optimal(:cost, method(:calculate_cost))
    when "fastest"
      find_optimal(:time, method(:calculate_time))
    else
      raise "Invalid criteria"
    end
  end

  private

  def find_cheapest_direct
    cheapest_sailing = nil
    @sailings.each do |sailing|
      next unless direct_sailing?(sailing)

      sailing_rate = find_sailing_rate(sailing["sailing_code"])
      next unless sailing_rate

      rate_in_eur = calculate_cost(sailing)
      next unless rate_in_eur

      cheapest_sailing = update_cheapest_sailing(cheapest_sailing, sailing, sailing_rate, rate_in_eur)
    end

    cheapest_sailing&.delete("rate_in_eur")
    cheapest_sailing
  end

  def update_cheapest_sailing(current_cheapest, sailing, sailing_rate, rate_in_eur)
    if current_cheapest.nil? || rate_in_eur < current_cheapest["rate_in_eur"]
      sailing.merge(sailing_rate, "rate_in_eur" => rate_in_eur)
    else
      current_cheapest
    end
  end

  def find_optimal(weight_key, weight_calculator)
    ports = ports_hash(weight_key)
    ports[@origin_port][weight_key] = 0
    queue = [@origin_port]

    until queue.empty?
      current_port = queue.shift
      current_info = ports[current_port]
      sailings = sailings_from_current_port(current_port, current_info[:arrival_date])

      sailings.each do |sailing|
        destination_port = sailing["destination_port"]

        weight = weight_calculator.call(sailing)
        next unless weight

        new_weight = current_info[weight_key] + weight
        next unless new_weight < ports[destination_port][weight_key]

        update_port_info(new_weight, current_info, sailing, weight_key, ports)

        # We do not want to process ports from the last destination
        queue << destination_port unless destination_port == @destination_port
      end
    end
    ports[@destination_port][:path]
  end

  def update_port_info(new_weight, current_info, sailing, weight_key, ports)
    destination_port = sailing["destination_port"]
    ports[destination_port][weight_key] = new_weight
    sailing_data = sailing.merge(find_sailing_rate(sailing["sailing_code"]))
    ports[destination_port][:path] = current_info[:path] + [sailing_data]
    ports[destination_port][:arrival_date] = Date.parse(sailing["arrival_date"])
  end

  def find_sailing_rate(sailing_code)
    Rails.cache.fetch("v1_sailing_rate/#{sailing_code}", expires_in: 12.hours) do
      @rates.find { |rate| rate["sailing_code"] == sailing_code }
    end
  end

  def sailings_from_current_port(current_port, arrival_date)
    # We select only the sailing that:
    # 1. has the same origin_port as the current_port
    # 2. will not depart ealier than the current arrival date (if it exists)
    # 3. will not go back to the origin_port (although this is already handled where origin weight are zero)
    @sailings.select do |sailing|
      (sailing["origin_port"] == current_port) &&
        (!arrival_date || Date.parse(sailing["departure_date"]) > arrival_date) &&
        (sailing["destination_port"] != @origin_port)
    end
  end

  def converter
    @converter ||= CurrencyConverter.new(@exchange_rates)
  end

  def ports_hash(weight_key)
    Hash.new { |hash, key| hash[key] = { weight_key => Float::INFINITY, path: [], arrival_date: nil } }
  end

  def calculate_cost(sailing)
    sailing_rate = find_sailing_rate(sailing["sailing_code"])
    return nil unless sailing_rate

    converter.convert(
      amount: sailing_rate["rate"],
      currency: sailing_rate["rate_currency"],
      date: sailing["departure_date"]
    )
  end

  def calculate_time(sailing)
    (Date.parse(sailing["arrival_date"]) - Date.parse(sailing["departure_date"])).to_i
  end

  def direct_sailing?(sailing)
    sailing["origin_port"] == @origin_port && sailing["destination_port"] == @destination_port
  end
end
