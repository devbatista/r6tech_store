module Admin::ProductsHelper
  # Each option carries whether its category uses RAM/storage variations, so the
  # form can switch between the variation builder and the simple color/storage UI.
  def category_options
    Category.all.map do |c|
      [c.name, c.id, { data: { uses_variants: c.uses_variants? } }]
    end
  end

  def storage_options
    Storage.all.collect { |s| [s.value, s.id] }
  end

  def memory_options
    Memory.all.collect { |m| [m.value, m.id] }
  end

  def color_options
    Color.all
  end
end
