class CreateFollowedUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :followed_users do |t|
      t.integer :follower_id
      t.integer :followed_id

      t.timestamps
    end
  end
end
