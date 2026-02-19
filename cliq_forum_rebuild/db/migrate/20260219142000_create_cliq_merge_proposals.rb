class CreateCliqMergeProposals < ActiveRecord::Migration[8.0]
    def change
      create_table :cliq_merge_proposals do |t|
        t.references :source_cliq, null: false, foreign_key: { to_table: :cliqs }
        t.references :target_cliq, null: false, foreign_key: { to_table: :cliqs }
        t.references :proposer, null: false, foreign_key: { to_table: :users }
        
        t.integer :status, default: 0, null: false
        t.datetime :phase_1_expires_at
        t.datetime :phase_2_expires_at
        t.integer :yes_votes, default: 0, null: false
        t.integer :no_votes, default: 0, null: false
  
        t.timestamps
      end

      # Add reference to posts for the discussion
      add_reference :posts, :cliq_merge_proposal, null: true, foreign_key: true
      
      # Add kind column as requested, defaulting to 0
      add_column :posts, :kind, :integer, default: 0
    end
  end
