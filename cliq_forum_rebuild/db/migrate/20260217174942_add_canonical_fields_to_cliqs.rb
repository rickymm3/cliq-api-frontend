class AddCanonicalFieldsToCliqs < ActiveRecord::Migration[8.0]
  def change
    add_reference :cliqs, :canonical, null: true, foreign_key: { to_table: :cliqs }
    add_column :cliqs, :lens, :string
  end
end
