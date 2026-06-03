puts "Clearing old data..."

OrderItem.delete_all
Order.delete_all
Product.delete_all
Category.delete_all
Storage.delete_all
Color.delete_all
Address.delete_all
User.delete_all

puts "Clean environment"
