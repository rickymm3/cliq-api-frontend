class AddThemeColorToCliqs < ActiveRecord::Migration[8.0]
  def change
    add_column :cliqs, :theme_color, :string
  end
end
