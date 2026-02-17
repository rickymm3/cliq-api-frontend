class AddFollowIndicesAndCounters < ActiveRecord::Migration[8.0]
  def change
    # Add indices to followed_users
    add_index :followed_users, :follower_id
    add_index :followed_users, :followed_id
    add_index :followed_users, [:follower_id, :followed_id], unique: true

    # Add counter caches to users
    add_column :users, :followers_count, :integer, default: 0, null: false
    add_column :users, :following_count, :integer, default: 0, null: false
  end
end
