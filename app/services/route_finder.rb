class RouteFinder
  def initialize(sailings_by_origin, weight_calculator, rate_finder, max_stops)
    @sailings_by_origin = sailings_by_origin
    @weight_calculator = weight_calculator
    @rate_finder = rate_finder
    @max_stops = max_stops
  end

  def find_route(origin_port, destination_port)
    ports = PortsHash.new
    ports[origin_port][:weight] = 0
    queue = [origin_port]

    until queue.empty?
      current_port = queue.shift
      current_info = ports[current_port]

      (@sailings_by_origin[current_port] || []).each do |sailing|
        process_sailing(sailing, current_info, ports, queue, destination_port)
      end
    end

    ports[destination_port][:path]
  end

  private

  def process_sailing(sailing, current_info, ports, queue, destination_port_code)
    return unless valid_sailing?(sailing, current_info[:arrival_date])
    return if current_info[:stops] > @max_stops

    rate = @rate_finder.find_rate(sailing["sailing_code"])
    return unless rate

    weight = @weight_calculator.calculate(sailing, rate)
    return unless weight

    destination_port = sailing["destination_port"]
    new_weight = current_info[:weight] + weight

    return unless new_weight < ports[destination_port][:weight]

    update_port_info(ports, new_weight, current_info, sailing, rate)
    queue << destination_port unless destination_port == destination_port_code
  end

  def update_port_info(ports, new_weight, current_info, sailing, rate)
    port_info = ports[sailing["destination_port"]]
    port_info[:weight] = new_weight
    port_info[:path] = current_info[:path] + [sailing.merge(rate)]
    port_info[:arrival_date] = Date.parse(sailing["arrival_date"])
    port_info[:stops] = current_info[:stops] + 1
  end

  def valid_sailing?(sailing, arrival_date)
    !arrival_date || Date.parse(sailing["departure_date"]) > arrival_date
  end
end
