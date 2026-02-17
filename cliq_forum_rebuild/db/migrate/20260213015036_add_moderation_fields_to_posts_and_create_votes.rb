class AddModerationFieldsToPostsAndCreateVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :reports_count, :integer, default: 0

    create_table :moderation_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :vote_type, default: 0 # 0=keep, 1=delete
      t.timestamps
    end
    
    add_index :moderation_votes, [:user_id, :post_id], unique: true
  end
end
