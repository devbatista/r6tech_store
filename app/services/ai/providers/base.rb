module Ai
  module Providers
    class Base
      def generate_product_description(_context)
        raise NotImplementedError
      end

      def generate_product_image(_context)
        raise NotImplementedError
      end
    end
  end
end
