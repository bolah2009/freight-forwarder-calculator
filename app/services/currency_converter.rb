class CurrencyConverter
  def initialize(exchange_rates)
    @exchange_rates = exchange_rates
  end

  def convert(amount:, currency:, date:)
    return amount.to_f if currency == "EUR"
    rate = @exchange_rates[date]&.[](currency.downcase)
    return nil unless rate
    (amount.to_f / rate).round(2)
  end
end
