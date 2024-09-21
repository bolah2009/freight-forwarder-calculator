namespace :shipment do
  desc "Calculate shipment options"
  task calculate: :environment do
    puts <<-INFO
      Type the origin_port code (e.g. CNSHA) in the first line \n\
      the destination_port code (e.g. NLRTM) in the second line \n\
      and the criteria (cheapest-direct, cheapest, fastest) in third line \n\
      pressing Enter after each line\n
    INFO
    origin_port = $stdin.gets.chomp
    destination_port = $stdin.gets.chomp
    criteria = $stdin.gets.chomp

    unless %w[cheapest-direct cheapest fastest].include?(criteria)
      puts "Invalid criteria. Please enter 'cheapest-direct', 'cheapest', or 'fastest'."
      exit 1
    end

    processor = ShipmentProcessor.new(
      origin_port:,
      destination_port:,
      criteria:
    )

    begin
      result = processor.process
      puts JSON.pretty_generate(Array.wrap(result))
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end
