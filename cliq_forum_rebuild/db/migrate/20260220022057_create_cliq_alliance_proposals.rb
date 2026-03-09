class CreateCliqAllianceProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :cliq_alliance_proposals do |t|
      t.references :proposer, null: false, foreign_key: { to_table: :users }
      t.references :source_cliq, null: false, foreign_key: { to_table: :cliqs }
      t.references :target_cliq, null: false, foreign_key: { to_table: :cliqs }
      t.integer :status, default: 0, null: false
      t.integer :yes_votes, default: 0, null: false
      t.integer :no_votes, default: 0, null: false
      t.integer :threshold, default: 5, null: false
      t.text :description

      t.timestamps
    end
    add_index :cliq_alliance_proposals, [:source_cliq_id, :target_cliq_id, :status], unique: true, name: "index_cliq_alliance_proposals_on_cliq_pairing_and_status", where: "status IN (0, 1)"
  end
end
