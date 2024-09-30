require "rails_helper"

RSpec.describe DataLoader do
  describe ".fetch" do
    let(:file_path) { Rails.root.join("data/response.json") }
    let(:file_content) { '{"key": "value"}' }
    let(:parsed_json) { { "key" => "value" } }
    let(:result) { described_class.fetch }

    before do
      allow(File).to receive(:read).with(file_path).and_return(file_content)
      allow(JSON).to receive(:parse).with(file_content).and_return(parsed_json)
    end

    it "reads the correct file" do
      result
      expect(File).to have_received(:read).with(file_path)
    end

    it "parses the file content as JSON" do
      result
      expect(JSON).to have_received(:parse).with(file_content)
    end

    it "returns the parsed JSON" do
      expect(result).to eq(parsed_json)
    end
  end
end
