puts "Creating orders..."

# Customer (admin não tem pedidos)
customer = User.find_by(email: "robertson@virtualshop.com")

# Endereços do cliente
home = customer.addresses.find_by(label: "Casa")
work = customer.addresses.find_by(label: "Trabalho")

# Find products
iphone = Product.find_by(name: "iPhone 16")
ipad = Product.find_by(name: "iPad Pro 13” M4")
watch = Product.find_by(name: "Apple Watch Series 10")
macbook = Product.find_by(name: "MacBook Air M3")
airpods = Product.find_by(name: "AirPods Pro (2nd generation)")
case_iphone = Product.find_by(name: "Case for iPhone")

# Order 1: customer, paid
order1 = Order.new(
  user: customer,
  total: iphone.price + ipad.price,
  status: "paid"
)
order1.assign_shipping_address(home)
order1.save!
OrderItem.create!(order: order1, product: iphone, quantity: 1, price: iphone.price)
OrderItem.create!(order: order1, product: ipad, quantity: 1, price: ipad.price)

# Order 2: customer, pending
order2 = Order.new(
  user: customer,
  total: watch.price * 2,
  status: "pending"
)
order2.assign_shipping_address(work)
order2.save!
OrderItem.create!(order: order2, product: watch, quantity: 2, price: watch.price)

# Order 3: customer, shipped
order3 = Order.new(
  user: customer,
  total: macbook.price + airpods.price,
  status: "shipped"
)
order3.assign_shipping_address(home)
order3.save!
OrderItem.create!(order: order3, product: macbook, quantity: 1, price: macbook.price)
OrderItem.create!(order: order3, product: airpods, quantity: 1, price: airpods.price)

# Order 4: customer, cancelled
order4 = Order.new(
  user: customer,
  total: case_iphone.price * 3,
  status: "cancelled"
)
order4.assign_shipping_address(home)
order4.save!
OrderItem.create!(order: order4, product: case_iphone, quantity: 3, price: case_iphone.price)

puts "Orders created successfully"
