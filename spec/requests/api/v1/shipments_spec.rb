require "rails_helper"

RSpec.describe "Api::V1::Shipments" do
  shared_examples "a successful request" do
    it "respond with a success status" do
      expect(response).to have_http_status(:success)
    end
  end

  shared_examples "an unsuccessful request" do
    it "respond with a success status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/shipments" do
    let(:headers) { { "Content-Type" => "application/json" } }
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
    let(:json_response) { response.parsed_body }

    before do
      allow(DataLoader).to receive(:fetch).and_return(data)
    end

    context "when valid parameters are provided" do
      let(:params) do
        {
          origin_port: "CNSHA",
          destination_port: "NLRTM",
          criteria: "cheapest-direct"
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

      let(:expected_response) do
        [
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
      end

      before { post("/api/v1/shipments", params:, headers:) }

      it "returns the shipment options" do
        expect(json_response).to eq(expected_response)
      end

      it_behaves_like "a successful request"
    end

    context "when invalid criteria is provided" do
      let(:params) do
        {
          origin_port: "CNSHA",
          destination_port: "NLRTM",
          criteria: "invalid-criteria"
        }.to_json
      end

      before { post("/api/v1/shipments", params:, headers:) }

      it "returns an error message" do
        expected_response = { "error" => "Invalid criteria" }
        expect(json_response).to eq(expected_response)
      end

      it_behaves_like "an unsuccessful request"
    end

    context "when required parameters are missing" do
      let(:params) do
        {
          origin_port: "CNSHA",
          criteria: "cheapest-direct"
        }.to_json
      end

      before { post("/api/v1/shipments", params:, headers:) }

      it "returns an error message" do
        expected_response = { "error" => "Missing required parameters" }
        expect(json_response).to eq(expected_response)
      end

      it_behaves_like "an unsuccessful request"
    end

    context "when no sailings are found" do
      let(:params) do
        {
          origin_port: "CNSHA",
          destination_port: "NONEXISTENT",
          criteria: "cheapest-direct"
        }.to_json
      end

      let(:sailings) { [] }
      let(:rates) { [] }
      let(:exchange_rates) { {} }

      before { post("/api/v1/shipments", params:, headers:) }

      it "returns an empty array" do
        expect(json_response).to eq([])
      end

      it_behaves_like "a successful request"
    end

    context "when an exception occurs during processing" do
      let(:params) do
        {
          origin_port: "CNSHA",
          destination_port: "NLRTM",
          criteria: "cheapest-direct"
        }.to_json
      end

      let(:shipment_processor) { instance_double(ShipmentProcessor) }

      before do
        allow(ShipmentProcessor).to receive(:new).and_return(shipment_processor)
        allow(shipment_processor).to receive(:process).and_raise(StandardError, "Something went wrong")
        post("/api/v1/shipments", params:, headers:)
      end

      it "returns an error message" do
        expected_response = { "error" => "Something went wrong" }
        expect(json_response).to eq(expected_response)
      end

      it_behaves_like "an unsuccessful request"
    end
  end
end
