require 'rails_helper'

RSpec.describe "Api::V1::Shipments", type: :request do
  describe 'POST /api/v1/shipments' do
    let(:headers) { { 'Content-Type' => 'application/json' } }

    before do
      allow(DataLoader).to receive(:load_data).and_return(data)
    end

    let(:sailings) { [] }
    let(:rates) { [] }
    let(:exchange_rates) { {} }

    let(:data) do
      {
        "sailings" => sailings,
        "rates" => rates,
        "exchange_rates" => exchange_rates
      }
    end
    let(:json_response) { JSON.parse(response.body) }

    context 'when valid parameters are provided' do
      let(:params) do
        {
          origin_port: 'CNSHA',
          destination_port: 'NLRTM',
          criteria: 'cheapest-direct'
        }.to_json
      end

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
            "usd" => 1.1260
          }
        }
      end

      it 'returns the shipment options' do
        post '/api/v1/shipments', params: params, headers: headers

        expect(response).to have_http_status(:ok)

        expected_response = [
          {
            "origin_port" => "CNSHA",
            "destination_port" => "NLRTM",
            "departure_date" => "2022-02-01",
            "arrival_date" => "2022-03-01",
            "sailing_code" => "ABCD",
            "rate" => "589.30",
            "rate_currency" => "USD"
          }
        ]

        expect(json_response).to eq(expected_response)
      end
    end

    context 'when invalid criteria is provided' do
      let(:params) do
        {
          origin_port: 'CNSHA',
          destination_port: 'NLRTM',
          criteria: 'invalid-criteria'
      }.to_json
      end

      it 'returns an error message' do
        post '/api/v1/shipments', params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expected_response = { "error" => "Invalid criteria" }
        expect(json_response).to eq(expected_response)
      end
    end

    context 'when required parameters are missing' do
      let(:params) do
        {
          origin_port: 'CNSHA',
          criteria: 'cheapest-direct'
        }.to_json
      end

      it 'returns an error message' do
        post '/api/v1/shipments', params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expected_response = { "error" => "Missing required parameters" }
        expect(json_response).to eq(expected_response)
      end
    end

    context 'when no sailings are found' do
      let(:params) do
        {
          origin_port: 'CNSHA',
          destination_port: 'NONEXISTENT',
          criteria: 'cheapest-direct'
        }.to_json
      end

      let(:sailings) { [] }
      let(:rates) { [] }
      let(:exchange_rates) { {} }

      it 'returns an empty array' do
        post '/api/v1/shipments', params: params, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([ {} ])
      end
    end

    context 'when an exception occurs during processing' do
      let(:params) do
        {
          origin_port: 'CNSHA',
          destination_port: 'NLRTM',
          criteria: 'cheapest-direct'
        }.to_json
      end

      before do
        allow_any_instance_of(ShipmentProcessor).to receive(:process).and_raise(StandardError, 'Something went wrong')
      end

      it 'returns an error message' do
        post '/api/v1/shipments', params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expected_response = { "error" => "Something went wrong" }
        expect(json_response).to eq(expected_response)
      end
    end
  end
end
