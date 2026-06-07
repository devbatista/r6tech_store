puts "Creating products..."

products = [
  {
    name: "iPhone 17 Pro Max", category: "Iphones", description: "Novo.",
    colors: ["Preto", "Prata", "Azul", "Titânio"],
    storages: { "256GB" => 9_000, "512GB" => 10_000, "1TB" => 11_000, "2TB" => 12_500 }
  },
  {
    name: "iPhone 17 Pro", category: "Iphones", description: "Novo.",
    colors: ["Titânio", "Prata", "Azul", "Preto"],
    storages: { "256GB" => 8_400, "512GB" => 9_500, "1TB" => 10_150 }
  },
  {
    name: "iPhone 17", category: "Iphones", description: "Novo.",
    colors: ["Preto", "Azul", "Rosa", "Estelar"], storages: { "256GB" => 6_000 }
  },
  {
    name: "iPhone 16 Pro Max", category: "Iphones", description: "Novo.",
    colors: ["Preto", "Desert"], storages: { "512GB" => 8_500 }
  },
  {
    name: "iPhone 16 Pro", category: "Iphones", description: "Novo.",
    colors: ["Branco"], storages: { "128GB" => 6_500 }
  },
  {
    name: "iPhone 16", category: "Iphones",
    description: "Novo. A disponibilidade de cores varia conforme o armazenamento.",
    colors: ["Verde", "Azul", "Preto", "Branco", "Rosa"],
    storages: { "128GB" => 5_100, "256GB" => 5_700 }
  },
  {
    name: "iPhone 15 Plus", category: "Iphones", description: "Novo.",
    colors: ["Titânio natural", "Azul", "Branco", "Preto"], storages: { "128GB" => 4_700 }
  },
  {
    name: "iPhone 15", category: "Iphones", description: "Novo.",
    colors: ["Titânio natural", "Azul", "Branco", "Preto"], storages: { "128GB" => 4_200 }
  },
  {
    name: "iPhone 14", category: "Iphones", description: "Novo.",
    colors: ["Vários"], storages: { "128GB" => 3_950 }
  },
  {
    name: "iPhone 13", category: "Iphones", description: "Novo. Consultar disponibilidade.",
    colors: ["Consultar disponibilidade"], storages: { "128GB" => 3_600 }
  },
  {
    name: "iPhone 12 / 12 Mini", category: "Iphones", description: "Usado. Consultar valor.",
    colors: ["Roxo", "Azul", "Preto", "Branco", "Verde"],
    storages: { "64GB" => 0, "128GB" => 0 }
  },
  {
    name: "MacBook Pro M5 Max 14”", category: "Macs", description: "Novo.",
    colors: ["Space Black"],
    variants: [["24GB", "2TB", 25_000], ["36GB", "2TB", 30_000]]
  },
  {
    name: "MacBook Pro M5 Pro 14”", category: "Macs", description: "Novo.",
    colors: ["Space Black", "Silver"], variants: [["24GB", "1TB", 18_000]]
  },
  {
    name: "MacBook Pro M5 14”", category: "Macs", description: "Novo.",
    colors: ["Space Black", "Silver"], variants: [["16GB", "1TB", 12_500]]
  },
  {
    name: "MacBook Air M5 15”", category: "Macs", description: "Novo.",
    colors: ["Azul", "Midnight", "Silver"], variants: [["16GB", "512GB", 10_200]]
  },
  {
    name: "MacBook Air M5 13”", category: "Macs",
    description: "Novo. A disponibilidade de cores varia conforme a configuração.",
    colors: ["Starlight", "Azul", "Silver", "Midnight"],
    variants: [["16GB", "512GB", 7_800], ["16GB", "1TB", 9_900]]
  },
  {
    name: "MacBook Pro M4 15”", category: "Macs", description: "Novo.",
    colors: ["Space Black"], variants: [["16GB", "1TB", 12_000]]
  },
  {
    name: "MacBook Air M4 15”", category: "Macs",
    description: "Novo. A disponibilidade de cores varia conforme a configuração.",
    colors: ["Azul", "Midnight"],
    variants: [["16GB", "512GB", 8_500], ["24GB", "512GB", 11_000]]
  },
  {
    name: "MacBook Air M4 13”", category: "Macs",
    description: "Novo. A disponibilidade de cores varia conforme a configuração.",
    colors: ["Azul", "Silver", "Midnight", "Sky Blue", "Starlight"],
    variants: [["16GB", "256GB", 7_300], ["24GB", "512GB", 9_900]]
  },
  {
    name: "iPad Pro M5 11”", category: "Ipads", description: "Novo. Wi-Fi.",
    colors: ["Silver", "Space Black"], storages: { "256GB" => 6_900 }
  },
  {
    name: "iPad Pro M4 11”", category: "Ipads", description: "Novo. Wi-Fi.",
    colors: ["Silver"], storages: { "256GB" => 6_500 }
  },
  {
    name: "iPad Air M4 11”", category: "Ipads", description: "Novo. Wi-Fi.",
    colors: ["Azul", "Purple", "Starlight", "Cinza"], storages: { "128GB" => 4_700 }
  },
  {
    name: "iPad Air M3 11”", category: "Ipads",
    description: "Novo. Wi-Fi. A disponibilidade de cores varia conforme o armazenamento.",
    colors: ["Purple", "Azul", "Cinza", "Starlight"],
    storages: { "128GB" => 4_400, "256GB" => 4_700 }
  },
  {
    name: "iPad A16 11”", category: "Ipads",
    description: "Novo. Wi-Fi. A disponibilidade de cores varia conforme o armazenamento.",
    colors: ["Amarelo", "Azul", "Rosa", "Silver"],
    storages: { "128GB" => 2_800, "256GB" => 4_000 }
  },
  {
    name: "Apple Watch Series 11 46mm", category: "Watches", description: "Novo.",
    colors: ["Space Grey", "Jet Black", "Rose"], price: 2_700
  },
  {
    name: "Apple Watch Series 11 42mm", category: "Watches", description: "Novo.",
    colors: ["Space Grey", "Jet Black", "Rose", "Silver"], price: 2_600
  },
  {
    name: "Apple Watch SE3 44mm", category: "Watches", description: "Novo.",
    colors: ["Preto"], price: 2_400
  },
  {
    name: "Apple Watch SE3 40mm", category: "Watches", description: "Novo.",
    colors: ["Preto", "Starlight"], price: 2_150
  },
  {
    name: "Apple Watch SE2 44mm", category: "Watches", description: "Novo.",
    colors: ["Preto"], price: 1_700
  }
]

products.each do |attributes|
  storages = attributes.fetch(:storages, {})
  variants = attributes.fetch(:variants, [])
  product = Product.create!(
    name: attributes.fetch(:name),
    description: attributes.fetch(:description),
    price: attributes[:price] || storages.values.min || variants.map(&:last).min,
    category: Category.find_by!(name: attributes.fetch(:category))
  )

  attributes.fetch(:colors).each do |color_name|
    ProductColor.create!(product: product, color: Color.find_by!(name: color_name))
  end

  storages.each do |value, price|
    ProductStorage.create!(product: product, storage: Storage.find_by!(value: value), price: price)
  end

  variants.each do |memory, storage, price|
    ProductVariant.create!(
      product: product,
      memory: Memory.find_by!(value: memory),
      storage: Storage.find_by!(value: storage),
      price: price
    )
  end
end

puts "Products created successfully"
