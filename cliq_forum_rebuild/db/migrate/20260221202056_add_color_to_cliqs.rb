class AddColorToCliqs < ActiveRecord::Migration[8.0]
  def change
    add_column :cliqs, :color, :string
  end
end
