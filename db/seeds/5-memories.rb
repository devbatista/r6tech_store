puts "Creating memories"

Memory::VALID_MEMORIES.each do |value|
  Memory.create!(value: value)
end

puts "Memories created successfully"
