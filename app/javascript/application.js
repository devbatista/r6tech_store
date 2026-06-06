// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Stream action used by cart_items responses to slide the cart drawer open.
window.Turbo.StreamActions.open_cart = function () {
  document.dispatchEvent(new CustomEvent("cart:open"))
}
