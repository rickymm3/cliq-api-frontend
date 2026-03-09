class CreateCliqAlliances < ActiveRecord::Migration[8.0]
  def change
    create_table :cliq_alliances do |t|
      t.references :source_cliq, null: false, foreign_key: { to_table: :cliqs }
      t.references :target_cliq, null: false, foreign_key: { to_table: :cliqs }

      t.timestamps
    end
    add_index :cliq_alliances, [:source_cliq_id, :target_cliq_id], unique: true
  end
end
