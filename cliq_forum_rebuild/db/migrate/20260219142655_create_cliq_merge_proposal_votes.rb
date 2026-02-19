class CreateCliqMergeProposalVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :cliq_merge_proposal_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cliq_merge_proposal, null: false, foreign_key: true
      t.boolean :value, null: false

      t.timestamps
    end
    add_index :cliq_merge_proposal_votes, [:user_id, :cliq_merge_proposal_id], unique: true
  end
end
