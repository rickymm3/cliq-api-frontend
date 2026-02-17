class AddDescriptionToCliqs < ActiveRecord::Migration[8.0]
  def change
    add_column :cliqs, :description, :text
  end
end
