class DataLoader
  require "json"

  def self.load_data
    file_path = Rails.root.join("data", "response.json")
    JSON.parse(File.read(file_path))
  end
end
