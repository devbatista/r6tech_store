

puts "Creating colors"

{
  "Amarelo" => "#f4df81",
  "Azul" => "#7896ad",
  "Branco" => "#f5f5f0",
  "Cinza" => "#8e8e93",
  "Consultar disponibilidade" => "#a7a7a7",
  "Desert" => "#c3aa97",
  "Estelar" => "#f0e4d3",
  "Jet Black" => "#151515",
  "Midnight" => "#20242b",
  "Preto" => "#1d1d1f",
  "Prata" => "#d9d9d6",
  "Purple" => "#b8a8c9",
  "Rosa" => "#e8b6c2",
  "Rose" => "#d8a0a6",
  "Roxo" => "#8f76a8",
  "Silver" => "#d6d6d4",
  "Sky Blue" => "#a7c4d8",
  "Space Black" => "#333336",
  "Space Grey" => "#68686a",
  "Starlight" => "#eee6d8",
  "Titânio" => "#8f8a83",
  "Titânio natural" => "#c8c4bb",
  "Vários" => "#a7a7a7",
  "Verde" => "#9cbfa7"
}.each do |name, hex|
  Color.create!(name: name, hex: hex)
end

puts "Colors created successfully"
