class CreateCliqAllianceProposalVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :cliq_alliance_proposal_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cliq_alliance_proposal, null: false, foreign_key: true
      t.boolean :value, null: false

      t.timestamps
    end
    add_index :cliq_alliance_proposal_votes, [:user_id, :cliq_alliance_proposal_id], unique: true, name: 'index_votes_on_user_and_alliance_proposal'
  end
end
