if defined?(PryByebug)
  Pry.commands.alias_command "c", "continue"
  Pry.commands.alias_command "s", "step"
  Pry.commands.alias_command "n", "next"
  Pry.commands.alias_command "f", "finish"
end

# Hit Enter to repeat last command
Pry::Commands.command(/^$/, "repeat last command") do
  pry_instance.run_command Pry.history.to_a.last
end

def run_processor(origin_port = "CNSHA", destination_port = "NLRTM", criteria = "cheapest")
  processor = ShipmentProcessor.new(
    origin_port:,
    destination_port:,
    criteria:
  )

  processor.process
end
