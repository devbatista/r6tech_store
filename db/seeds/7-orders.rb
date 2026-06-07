puts "Creating orders..."

customer = User.find_by!(email: "robertson@virtualshop.com")
home = customer.addresses.find_by!(label: "Casa")
work = customer.addresses.find_by!(label: "Trabalho")

iphone = Product.find_by!(name: "iPhone 17 Pro Max")
ipad = Product.find_by!(name: "iPad Pro M5 11”")
watch = Product.find_by!(name: "Apple Watch Series 11 46mm")
macbook = Product.find_by!(name: "MacBook Air M5 13” 16GB")

[
  { status: "paid", address: home, items: [[iphone, 1], [ipad, 1]] },
  { status: "pending", address: work, items: [[watch, 2]] },
  { status: "shipped", address: home, items: [[macbook, 1]] },
  { status: "cancelled", address: home, items: [[iphone, 1]] }
].each do |attributes|
  total = attributes.fetch(:items).sum { |product, quantity| product.price * quantity }
  order = Order.new(user: customer, total: total, status: attributes.fetch(:status))
  order.assign_shipping_address(attributes.fetch(:address))
  order.save!

  attributes.fetch(:items).each do |product, quantity|
    OrderItem.create!(order: order, product: product, quantity: quantity, price: product.price)
  end
end

puts "Orders created successfully"
