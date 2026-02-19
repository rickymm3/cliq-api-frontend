
class CreateCliqAliasProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :cliq_alias_proposals do |t|
      t.references :cliq, null: false, foreign_key: true
      t.references :parent_cliq, null: false, foreign_key: { to_table: :cliqs }
      t.string :alias_name, null: false
      t.string :lens
      t.references :proposer, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0
      t.integer :votes_count, default: 0

      t.timestamps
    end
  end
end
