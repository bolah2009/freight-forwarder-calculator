class PortsHash
  def initialize
    @ports = Hash.new { |hash, key| hash[key] = default_port }
  end

  def [](key)
    @ports[key]
  end

  private

  def default_port
    {
      weight: Float::INFINITY,
      path: [],
      arrival_date: nil,
      stops: 0
    }
  end
end
