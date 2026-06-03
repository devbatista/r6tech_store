class Admin::StocksController < Admin::BaseAdminController
  before_action :set_product, only: [:new, :create]
  before_action :set_stock, only: [:show, :edit, :update, :destroy]

  def show;end

  def new
    @stock = @product.product_stocks.build
  end

  def create
    @stock = @product.product_stocks.build(stock_params)
    if @stock.save
      redirect_to admin_product_path(@product), notice: "Estoque criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit;end

  def update
    if @stock.update(stock_params)
      redirect_to admin_product_path(@stock.product), notice: "Estoque atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_product
      @product = Product.find(params[:product_id])
    end

    def set_stock
      @stock = ProductStock.find(params[:id])
    end

    def stock_params
      params.require(:product_stock).permit(:quantity, :color_id, :storage_id)
    end
end
