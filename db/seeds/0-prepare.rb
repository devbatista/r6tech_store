puts "Clearing old data..."

CartItem.delete_all
Cart.delete_all
OrderItem.delete_all
Order.delete_all
ProductVariant.delete_all
ProductStorage.delete_all
ProductColor.delete_all
Product.delete_all
Category.delete_all
Storage.delete_all
Memory.delete_all
Color.delete_all
Address.delete_all
User.delete_all

puts "Clean environment"
