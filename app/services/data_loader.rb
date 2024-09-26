class DataLoader
  def self.fetch
    file_path = Rails.root.join("data/response.json")
    JSON.parse(File.read(file_path))
  end
end
