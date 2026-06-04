class AddAiSuggestionsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :ai_description, :text
    add_column :products, :ai_description_status, :string, null: false, default: "idle"
    add_column :products, :ai_image_status, :string, null: false, default: "idle"
    add_column :products, :ai_error, :text
  end
end
