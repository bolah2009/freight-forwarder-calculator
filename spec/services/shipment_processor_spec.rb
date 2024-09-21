require "rails_helper"

RSpec.describe ShipmentProcessor, type: :service do
  let(:exchange_rates) { {} }
  let(:processor) do
    described_class.new(
      origin_port:,
      destination_port:,
      criteria:
    )
  end
  let(:sailings) { [] }
  let(:rates) { [] }
  let(:data) do
    {
      "sailings" => sailings,
      "rates" => rates,
      "exchange_rates" => exchange_rates
    }
  end

  let(:result) { processor.process }

  before do
    allow(DataLoader).to receive(:load_data).and_return(data)
  end

  describe "#find_cheapest_direct" do
    let(:criteria) { "cheapest-direct" }

    context "when direct sailings are available" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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
      let(:expected_result) do
        {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-01",
          "arrival_date" => "2022-03-01",
          "sailing_code" => "ABCD",
          "rate" => "589.30",
          "rate_currency" => "USD"
        }
      end

      it "returns the cheapest direct sailing" do
        expect(result).to eq(expected_result)
      end
    end

    context "when multiple direct sailings have the same rate in EUR" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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

      let(:expected_result) do
        {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-01",
          "arrival_date" => "2022-03-01",
          "sailing_code" => "ABCD",
          "rate" => "100",
          "rate_currency" => "EUR"
        }
      end

      it "returns the first sailing found with the cheapest rate" do
        expect(result).to eq(expected_result)
      end
    end

    context "when no direct sailings are available" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NONEXISTENT" }

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

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when a sailing has no associated rate" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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

      let(:expected_result) do
        {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-02",
          "arrival_date" => "2022-03-02",
          "sailing_code" => "EFGH",
          "rate" => "890.32",
          "rate_currency" => "EUR"
        }
      end

      it "skips the sailing without a rate and returns the cheapest among those with rates" do
        expect(result).to eq(expected_result)
      end
    end

    context "when exchange rate for a currency is missing" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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

      it "skips the sailing if exchange rate is missing and returns nil" do
        expect(result).to be_nil
      end
    end

    context "when sailing rate currency is unsupported" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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

      it "skips the sailing with unsupported currency and returns nil" do
        expect(result).to be_nil
      end
    end

    context "when all direct sailings are in EUR" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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
      let(:expected_result) do
        {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-02",
          "arrival_date" => "2022-03-02",
          "sailing_code" => "EFGH",
          "rate" => "450",
          "rate_currency" => "EUR"
        }
      end

      it "returns the sailing with the lower EUR rate" do
        expect(result).to eq(expected_result)
      end
    end

    context "when sailings have mixed currencies" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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
      let(:expected_result) do
        {
          "origin_port" => "CNSHA",
          "destination_port" => "NLRTM",
          "departure_date" => "2022-02-01",
          "arrival_date" => "2022-03-01",
          "sailing_code" => "ABCD",
          "rate" => "500",
          "rate_currency" => "USD"
        }
      end

      it "correctly converts rates and returns the cheapest sailing" do
        # Convert 500 USD on 2022-02-01
        # Rate in EUR: 500 / 1.1260 = ~444.05 EUR

        expect(result).to eq(expected_result)
      end
    end

    context "when sailing date has no exchange rate data" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

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

      it "skips the sailing and returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#find_cheapest" do
    let(:criteria) { "cheapest" }

    context "when there is a cheaper indirect route" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-12",
            "arrival_date" => "2022-01-15",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-05",
            "arrival_date" => "2022-01-20",
            "sailing_code" => "S3"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "S1",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S2",
            "rate" => "200",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S3",
            "rate" => "800",
            "rate_currency" => "EUR"
          }
        ]
      end
      let(:expected_result) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-12",
            "arrival_date" => "2022-01-15",
            "sailing_code" => "S2",
            "rate" => "200",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "returns the cheapest route including indirect sailings" do
        expect(result).to eq(expected_result)
      end
    end

    context "when the direct route is cheaper than indirect routes" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-12",
            "arrival_date" => "2022-01-15",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-05",
            "arrival_date" => "2022-01-20",
            "sailing_code" => "S3"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "S1",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S2",
            "rate" => "200",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S3",
            "rate" => "600",
            "rate_currency" => "EUR"
          }
        ]
      end
      let(:expected_result) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-05",
            "arrival_date" => "2022-01-20",
            "sailing_code" => "S3",
            "rate" => "600",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "returns the direct route as the cheapest option" do
        expect(result).to eq(expected_result)
      end
    end

    context "when a route points back to the origin route" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-12",
            "arrival_date" => "2022-01-15",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-05",
            "arrival_date" => "2022-01-20",
            "sailing_code" => "S3"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "CNSHA",
            "departure_date" => "2022-01-16",
            "arrival_date" => "2022-01-17",
            "sailing_code" => "S4"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "S1",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S2",
            "rate" => "100",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S4",
            "rate" => "50",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S3",
            "rate" => "800",
            "rate_currency" => "EUR"
          }
        ]
      end
      let(:expected_result) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-12",
            "arrival_date" => "2022-01-15",
            "sailing_code" => "S2",
            "rate" => "100",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "returns the cheapest route including indirect sailings" do
        expect(result).to eq(expected_result)
      end
    end

    context "when no route is available" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NONEXISTENT" }

      let(:sailings) { [] }
      let(:rates) { [] }
      let(:exchange_rates) { {} }

      it "returns an empty array" do
        expect(result).to eq([])
      end
    end

    context "when timing constraints prevent a route" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-10",
            "arrival_date" => "2022-01-20",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-15",
            "arrival_date" => "2022-01-25",
            "sailing_code" => "S2"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "S1",
            "rate" => "500",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S2",
            "rate" => "200",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "does not consider routes where departure is before arrival of previous leg" do
        expect(result).to eq([])
      end
    end

    context "when multiple routes have the same total cost" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-12",
            "arrival_date" => "2022-01-15",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "DEHAM",
            "departure_date" => "2022-01-02",
            "arrival_date" => "2022-01-11",
            "sailing_code" => "S3"
          },
          {
            "origin_port" => "DEHAM",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-13",
            "arrival_date" => "2022-01-16",
            "sailing_code" => "S4"
          }
        ]
      end

      let(:rates) do
        [
          {
            "sailing_code" => "S1",
            "rate" => "400",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S2",
            "rate" => "300",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S3",
            "rate" => "350",
            "rate_currency" => "EUR"
          },
          {
            "sailing_code" => "S4",
            "rate" => "350",
            "rate_currency" => "EUR"
          }
        ]
      end
      let(:possible_routes) do
        [
          [
            {
              "origin_port" => "CNSHA",
              "destination_port" => "ESBCN",
              "departure_date" => "2022-01-01",
              "arrival_date" => "2022-01-10",
              "sailing_code" => "S1",
              "rate" => "400",
              "rate_currency" => "EUR"
            },
            {
              "origin_port" => "ESBCN",
              "destination_port" => "NLRTM",
              "departure_date" => "2022-01-12",
              "arrival_date" => "2022-01-15",
              "sailing_code" => "S2",
              "rate" => "300",
              "rate_currency" => "EUR"
            }
          ],
          [
            {
              "origin_port" => "CNSHA",
              "destination_port" => "DEHAM",
              "departure_date" => "2022-01-02",
              "arrival_date" => "2022-01-11",
              "sailing_code" => "S3",
              "rate" => "350",
              "rate_currency" => "EUR"
            },
            {
              "origin_port" => "DEHAM",
              "destination_port" => "NLRTM",
              "departure_date" => "2022-01-13",
              "arrival_date" => "2022-01-16",
              "sailing_code" => "S4",
              "rate" => "350",
              "rate_currency" => "EUR"
            }
          ]
        ]
      end

      it "returns one of the routes with the lowest total cost" do
        total_cost = result.sum { |sailing| sailing["rate"].to_f }

        expect(total_cost).to eq(700.0)
      end

      it "returns one of the possible routes" do
        expect(possible_routes).to include(result)
      end
    end
  end

  describe "#find_fastest" do
    let(:criteria) { "fastest" }
    let(:rates) do
      [
        {
          "sailing_code" => "S1",
          "rate" => "100",
          "rate_currency" => "EUR"
        },
        {
          "sailing_code" => "S2",
          "rate" => "100",
          "rate_currency" => "EUR"
        },
        {
          "sailing_code" => "S3",
          "rate" => "100",
          "rate_currency" => "EUR"
        }
      ]
    end

    context "when there is a faster indirect route" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-05",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-06",
            "arrival_date" => "2022-01-08",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-02",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S3"
          }
        ]
      end
      let(:expected_result) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-05",
            "sailing_code" => "S1",
            "rate" => "100",
            "rate_currency" => "EUR"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-06",
            "arrival_date" => "2022-01-08",
            "sailing_code" => "S2",
            "rate" => "100",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "returns the fastest route including indirect sailings" do
        expect(result).to eq(expected_result)
      end
    end

    context "when the direct route is faster than indirect routes" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-06",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-07",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-02",
            "arrival_date" => "2022-01-08",
            "sailing_code" => "S3"
          }
        ]
      end

      let(:expected_result) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-02",
            "arrival_date" => "2022-01-08",
            "sailing_code" => "S3",
            "rate" => "100",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "returns the direct route as the fastest option" do
        expect(result).to eq(expected_result)
      end
    end

    context "when no route is available" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NONEXISTENT" }

      let(:sailings) { [] }
      let(:rates) { [] }
      let(:exchange_rates) { {} }

      it "returns an empty array" do
        expect(result).to eq([])
      end
    end

    context "when timing constraints prevent a route" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-05",
            "arrival_date" => "2022-01-10",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-08", # Departs before arrival at ESBCN
            "arrival_date" => "2022-01-12",
            "sailing_code" => "S2"
          }
        ]
      end

      it "does not consider routes where departure is before arrival of previous leg" do
        expect(result).to eq([])
      end
    end

    context "when multiple routes have the same earliest arrival date" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "DEHAM",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-05",
            "sailing_code" => "S1"
          },
          {
            "origin_port" => "DEHAM",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-06",
            "arrival_date" => "2022-01-08",
            "sailing_code" => "S2"
          },
          {
            "origin_port" => "CNSHA",
            "destination_port" => "ESBCN",
            "departure_date" => "2022-01-02",
            "arrival_date" => "2022-01-06",
            "sailing_code" => "S3"
          },
          {
            "origin_port" => "ESBCN",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-07",
            "arrival_date" => "2022-01-08",
            "sailing_code" => "S4"
          }
        ]
      end

      let(:possible_routes) do
        [
          [
            {
              "origin_port" => "CNSHA",
              "destination_port" => "DEHAM",
              "departure_date" => "2022-01-01",
              "arrival_date" => "2022-01-05",
              "sailing_code" => "S1",
              "rate" => "100",
              "rate_currency" => "EUR"
            },
            {
              "origin_port" => "DEHAM",
              "destination_port" => "NLRTM",
              "departure_date" => "2022-01-06",
              "arrival_date" => "2022-01-08",
              "sailing_code" => "S2",
              "rate" => "100",
              "rate_currency" => "EUR"
            }
          ],
          [
            {
              "origin_port" => "CNSHA",
              "destination_port" => "ESBCN",
              "departure_date" => "2022-01-02",
              "arrival_date" => "2022-01-06",
              "sailing_code" => "S3",
              "rate" => "100",
              "rate_currency" => "EUR"
            },
            {
              "origin_port" => "ESBCN",
              "destination_port" => "NLRTM",
              "departure_date" => "2022-01-07",
              "arrival_date" => "2022-01-08",
              "sailing_code" => "S4",
              "rate" => "100",
              "rate_currency" => "EUR"
            }
          ]
        ]
      end

      it "returns one of the routes with the earliest arrival date" do
        expected_arrival_date = Date.parse("2022-01-08")

        actual_arrival_date = Date.parse(result.last["arrival_date"])

        expect(actual_arrival_date).to eq(expected_arrival_date)
      end

      it "returns one of the possible routes" do
        expect(possible_routes).to include(result)
      end
    end

    context "when sailings have overlapping schedules but lead to earlier arrival" do
      let(:origin_port) { "CNSHA" }
      let(:destination_port) { "NLRTM" }

      let(:sailings) do
        [
          # Sailing that departs later but arrives earlier
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-03",
            "arrival_date" => "2022-01-06",
            "sailing_code" => "S1"
          },
          # Sailing that departs earlier but arrives later
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-01",
            "arrival_date" => "2022-01-07",
            "sailing_code" => "S2"
          }
        ]
      end

      let(:exchange_rates) { {} }
      let(:expected_result) do
        [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-01-03",
            "arrival_date" => "2022-01-06",
            "sailing_code" => "S1",
            "rate" => "100",
            "rate_currency" => "EUR"
          }
        ]
      end

      it "chooses the sailing with the earliest arrival date" do
        expect(result).to eq(expected_result)
      end
    end
  end
end
