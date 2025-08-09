class ReplaceDescriptionWithCostInEvents < ActiveRecord::Migration[8.0]
  def change
    remove_column :events, :description, :text
    add_column :events, :cost, :string
  end
end
