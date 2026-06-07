puts "Creating storage"

Storage::VALID_STORAGES.each do |value|
  Storage.create!(value: value)
end

puts "Storages created successfully"
