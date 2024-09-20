require 'rails_helper'

RSpec.describe ShipmentProcessor, type: :service do
  let(:exchange_rates) { [] }
  let(:data) do
    {
      "sailings" => sailings,
      "rates" => rates,
      "exchange_rates" => exchange_rates
    }
  end

  before do
    allow(DataLoader).to receive(:load_data).and_return(data)
  end

  let(:processor) do
    ShipmentProcessor.new(
      origin_port: origin_port,
      destination_port: destination_port,
      criteria: criteria
    )
  end

  describe '#find_cheapest_direct' do
    let(:criteria) { 'cheapest-direct' }

    context 'when direct sailings are available' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-02",
            "arrival_date" => "2022-03-02",
            "sailing_code" => "EFGH"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "589.30",
            "rate_currency" => "USD"
          },
          {
            "sailing_code" => "EFGH",
            "rate" => "890.32",
            "rate_currency" => "EUR"
          }
        ]
      end

      let(:exchange_rates) do
        {
          "2022-02-01" => {
            "usd" => 1.1260,
            "jpy" => 130.15
          }
        }
      end

      it 'returns the cheapest direct sailing' do
        expected_result = {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-01",
          "arrival_date" => "2022-03-01",
          "sailing_code" => "ABCD",
          "rate" => "589.30",
          "rate_currency" => "USD"
        }

        result = processor.process

        expect(result).to eq(expected_result)
      end
    end

    context 'when multiple direct sailings have the same rate in EUR' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-02",
            "arrival_date" => "2022-03-02",
            "sailing_code" => "EFGH"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "100",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "EFGH",
            "rate" => "112.60",
            "rate_currency" => "USD"
          }
        ]
      end

      let(:exchange_rates) do
        {
          "2022-02-02" => {
            "usd" => 1.1260
          }
        }
      end

      it 'returns the first sailing found with the cheapest rate' do
        expected_result = {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-01",
          "arrival_date" => "2022-03-01",
          "sailing_code" => "ABCD",
          "rate" => "100",
          "rate_currency" => "EUR"
        }

        result = processor.process

        expect(result).to eq(expected_result)
      end
    end

    context 'when no direct sailings are available' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NONEXISTENT' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          }
        ]
      end

      let(:rates) { [] }
      let(:exchange_rates) { {} }

      it 'returns an empty hash' do
        result = processor.process

        expect(result).to eq({})
      end
    end

    context 'when a sailing has no associated rate' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-02",
            "arrival_date" => "2022-03-02",
            "sailing_code" => "EFGH"
          }
        ]
      end

      let(:rates) do
        [
          # Missing rate for 'ABCD'
          {
            "sailing_code" => "EFGH",
            "rate" => "890.32",
            "rate_currency" => "EUR"
          }
        ]
      end

      it 'skips the sailing without a rate and returns the cheapest among those with rates' do
        expected_result = {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-02",
          "arrival_date" => "2022-03-02",
          "sailing_code" => "EFGH",
          "rate" => "890.32",
          "rate_currency" => "EUR"
        }

        result = processor.process

        expect(result).to eq(expected_result)
      end
    end

    context 'when exchange rate for a currency is missing' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "589.30",
            "rate_currency" => "USD"
          }
        ]
      end

      let(:exchange_rates) do
        {
          "2022-02-01" => {
            # Missing 'usd' exchange rate
            "jpy" => 130.15
          }
        }
      end

      it 'skips the sailing if exchange rate is missing and returns an empty hash' do
        result = processor.process

        expect(result).to eq({})
      end
    end

    context 'when sailing rate currency is unsupported' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "589.30",
            "rate_currency" => "GBP" # Unsupported currency
          }
        ]
      end

      let(:exchange_rates) do
        {
          "2022-02-01" => {
            "usd" => 1.1260,
            "jpy" => 130.15
          }
        }
      end

      it 'skips the sailing with unsupported currency and returns an empty hash' do
        result = processor.process

        expect(result).to eq({})
      end
    end

    context 'when all direct sailings are in EUR' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-02",
            "arrival_date" => "2022-03-02",
            "sailing_code" => "EFGH"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "EFGH",
            "rate" => "450",
            "rate_currency" => "EUR"
          }
        ]
      end

      it 'returns the sailing with the lower EUR rate' do
        expected_result = {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-02",
          "arrival_date" => "2022-03-02",
          "sailing_code" => "EFGH",
          "rate" => "450",
          "rate_currency" => "EUR"
        }

        result = processor.process

        expect(result).to eq(expected_result)
      end
    end

    context 'when sailings have mixed currencies' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-02",
            "arrival_date" => "2022-03-02",
            "sailing_code" => "EFGH"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "500",
            "rate_currency" => "USD"
          },
          {
            "sailing_code" => "EFGH",
            "rate" => "450",
            "rate_currency" => "EUR"
          }
        ]
      end

      let(:exchange_rates) do
        {
          "2022-02-01" => {
            "usd" => 1.1260
          }
        }
      end

      it 'correctly converts rates and returns the cheapest sailing' do
        # Convert 500 USD on 2022-02-01
        # Rate in EUR: 500 / 1.1260 = ~444.05 EUR
        expected_result = {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-01",
          "arrival_date" => "2022-03-01",
          "sailing_code" => "ABCD",
          "rate" => "500",
          "rate_currency" => "USD"
        }

        result = processor.process

        expect(result).to eq(expected_result)
      end
    end

    context 'when sailing date has no exchange rate data' do
      let(:origin_port) { 'CNSHA' }
      let(:destination_port) { 'NLRTM' }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-03-01",
            "arrival_date" => "2022-03-30",
            "sailing_code" => "ABCD"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "ABCD",
            "rate" => "500",
            "rate_currency" => "USD"
          }
        ]
      end

      let(:exchange_rates) do
        {
          "2022-02-01" => {
            "usd" => 1.1260
          }
        }
      end

      it 'skips the sailing and returns an empty hash' do
        result = processor.process

        expect(result).to eq({})
      end
    end
  end
end
