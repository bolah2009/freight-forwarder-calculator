class ShipmentProcessor
  def initialize(origin_port:, destination_port:, criteria:, max_stops: Float::INFINITY)
    @origin_port = origin_port
    @destination_port = destination_port
    @criteria = criteria
    data = DataLoader.load_data
    @sailings = data["sailings"]
    @max_stops = max_stops
    @sailings_by_origin = @sailings.group_by { |sailing| sailing["origin_port"] }
    @rates = data["rates"]
    @exchange_rates = data["exchange_rates"]
  end

  def process
    case @criteria
    when "cheapest-direct"
      @max_stops = 0
      @weight_key = :cost
      find_optimal(method(:calculate_cost))
    when "cheapest"
      @weight_key = :cost
      find_optimal(method(:calculate_cost))
    when "fastest"
      @weight_key = :time
      find_optimal(method(:calculate_time))
    else
      raise "Invalid criteria"
    end
  end

  private

  def find_optimal(weight_calculator)
    @ports = ports_hash
    @ports[@origin_port][@weight_key] = 0
    queue = [@origin_port]

    until queue.empty?
      current_port = queue.shift
      current_info = @ports[current_port]

      (@sailings_by_origin[current_port] || []).each do |sailing|
        process_sailing(sailing, queue, current_port, current_info, weight_calculator)
      end
    end
    @ports[@destination_port][:path]
  end

  def process_sailing(sailing, queue, current_port, current_info, weight_calculator)
    return unless valid_sailing?(sailing, current_port, current_info[:arrival_date])

    destination_port = sailing["destination_port"]
    return unless current_info[:stops] <= @max_stops

    weight = weight_calculator.call(sailing)
    return unless weight

    new_weight = current_info[@weight_key] + weight
    return unless new_weight < @ports[destination_port][@weight_key]

    update_port_info(new_weight, current_info, sailing)

    # We do not want to process ports from the last destination
    queue << destination_port unless destination_port == @destination_port
  end

  def update_port_info(new_weight, current_info, sailing)
    destination_port = sailing["destination_port"]
    @ports[destination_port][@weight_key] = new_weight
    sailing_data = sailing.merge(find_sailing_rate(sailing["sailing_code"]))
    @ports[destination_port][:path] = current_info[:path] + [sailing_data]
    @ports[destination_port][:stops] = current_info[:stops] + 1
    @ports[destination_port][:arrival_date] = Date.parse(sailing["arrival_date"])
  end

  def find_sailing_rate(sailing_code)
    Rails.cache.fetch("v1_sailing_rate/#{sailing_code}", expires_in: 12.hours) do
      @rates.find { |rate| rate["sailing_code"] == sailing_code }
    end
  end

  def valid_sailing?(sailing, _current_port, arrival_date)
    # We consider a sailing valid if it:
    # 1. will not depart ealier than the current arrival date (if it exists)
    # 2. will not go back to the origin_port (although this is already handled where origin weight are zero)
    (!arrival_date || Date.parse(sailing["departure_date"]) > arrival_date) &&
      (sailing["destination_port"] != @origin_port)
  end

  def converter
    @converter ||= CurrencyConverter.new(@exchange_rates)
  end

  def ports_hash
    Hash.new do |hash, key|
      hash[key] = { @weight_key => Float::INFINITY, path: [], arrival_date: nil, stops: 0 }
    end
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
end
