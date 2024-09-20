require 'swagger_helper'

RSpec.describe 'Shipments API', type: :request do
  path '/api/v1/shipments' do
    post 'Calculate shipment options' do
      tags 'Shipments'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :shipment, in: :body, schema: {
        type: :object,
        properties: {
          origin_port: { type: :string },
          destination_port: { type: :string },
          criteria: { type: :string, enum: [ 'cheapest-direct', 'cheapest', 'fastest' ] }
        },
        required: [ 'origin_port', 'destination_port', 'criteria' ]
      }

      let(:json_response) { JSON.parse(response.body) }

      response '200', 'shipment options calculated' do
        let(:shipment) { { origin_port: 'CNSHA', destination_port: 'NLRTM', criteria: 'cheapest-direct' } }

        before do
          allow(DataLoader).to receive(:load_data).and_return({
            "sailings" => [
              {
                "origin_port" => "CNSHA",
                "destination_port" => "NLRTM",
                "departure_date" => "2022-02-01",
                "arrival_date" => "2022-03-01",
                "sailing_code" => "ABCD"
              }
            ],
            "rates" => [
              {
                "sailing_code" => "ABCD",
                "rate" => "589.30",
                "rate_currency" => "USD"
              }
            ],
            "exchange_rates" => {
              "2022-02-01" => {
                "usd" => 1.1260
              }
            }
          })
        end

        run_test! do |response|
          expect(json_response).to eq([
            {
              "origin_port" => "CNSHA",
              "destination_port" => "NLRTM",
              "departure_date" => "2022-02-01",
              "arrival_date" => "2022-03-01",
              "sailing_code" => "ABCD",
              "rate" => "589.30",
              "rate_currency" => "USD"
            }
          ])
        end
      end

      response '422', 'invalid request' do
        let(:shipment) { { origin_port: 'CNSHA', criteria: 'cheapest-direct' } }

        run_test! do |response|
          expect(json_response).to eq({ "error" => "Missing required parameters" })
        end
      end

      response '422', 'invalid criteria' do
        let(:shipment) { { origin_port: 'CNSHA', destination_port: 'NLRTM', criteria: 'invalid' } }

        run_test! do |response|
          expect(json_response).to eq({ "error" => "Invalid criteria" })
        end
      end
    end
  end
end
