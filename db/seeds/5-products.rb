puts "Creating products..."

# Macs
Product.create!(
  name: "MacBook Air M3",
  description: "Apple MacBook Air with M3 chip",
  price: 12000,
  category: Category.find_by(name: "Macbook Air")
)

Product.create!(
  name: "MacBook Pro M3 Pro",
  description: "Apple MacBook Pro with M3 Pro chip",
  price: 18000,
  category: Category.find_by(name: "Macbook Pro")
)

Product.create!(
  name: "iMac 24”",
  description: "Apple iMac 24 inches",
  price: 15000,
  category: Category.find_by(name: "iMac")
)

# iPads
Product.create!(
  name: "iPad Pro 13” M4",
  description: "New iPad Pro with M4 chip",
  price: 11000,
  category: Category.find_by(name: "Ipad Pro")
)

Product.create!(
  name: "iPad Air 11”",
  description: "iPad Air 11 inches",
  price: 7000,
  category: Category.find_by(name: "Ipad Air")
)

# iPhones
Product.create!(
  name: "iPhone 16",
  description: "Apple iPhone 16",
  price: 9000,
  category: Category.find_by(name: "Iphone 16")
)

Product.create!(
  name: "iPhone 16 Pro",
  description: "Apple iPhone 16 Pro",
  price: 11000,
  category: Category.find_by(name: "Iphone 16 Pro")
)

Product.create!(
  name: "iPhone 15",
  description: "Apple iPhone 15",
  price: 7500,
  category: Category.find_by(name: "Iphone 15")
)

# Watches
Product.create!(
  name: "Apple Watch Series 10",
  description: "Apple Watch Series 10",
  price: 5000,
  category: Category.find_by(name: "Series 10")
)

Product.create!(
  name: "Apple Watch Ultra 2",
  description: "Apple Watch Ultra 2",
  price: 8000,
  category: Category.find_by(name: "Ultra 2")
)

# AirPods
Product.create!(
  name: "AirPods Pro (2nd generation)",
  description: "Apple AirPods Pro second generation",
  price: 2500,
  category: Category.find_by(name: "Pro")
)

Product.create!(
  name: "AirPods Max",
  description: "Apple AirPods Max",
  price: 4500,
  category: Category.find_by(name: "Max")
)

# Accessories
Product.create!(
  name: "Case for MacBook",
  description: "Protective case for MacBook",
  price: 300,
  category: Category.find_by(name: "Mac")
)

Product.create!(
  name: "Case for iPhone",
  description: "Protective case for iPhone",
  price: 200,
  category: Category.find_by(name: "Iphone")
)

# iPhone 15 Pro Max — with selectable color and storage options.
iphone_15_pro_max = Product.find_or_create_by!(name: "iPhone 15 Pro Max") do |product|
  product.description = "Apple iPhone 15 Pro Max em titânio, com chip A17 Pro, tela Super Retina XDR de 6,7\" e câmera de 48MP."
  product.price = 10_499
  product.category = Category.find_by(name: "Iphone 15 Pro Max")
end

["Titanium black", "Titanium white", "Titanium natural", "Titanium desert"].each do |color_name|
  color = Color.find_by(name: color_name)
  ProductColor.find_or_create_by!(product: iphone_15_pro_max, color: color) if color
end

{ "256GB" => 10_499, "512GB" => 11_999, "1TB" => 13_499 }.each do |value, price|
  storage = Storage.find_by(value: value)
  next unless storage

  ProductStorage.find_or_create_by!(product: iphone_15_pro_max, storage: storage) do |ps|
    ps.price = price
  end
end

puts "Products created successfully"