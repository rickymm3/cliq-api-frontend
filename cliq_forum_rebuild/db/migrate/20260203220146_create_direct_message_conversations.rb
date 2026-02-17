class CreateDirectMessageConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :direct_message_conversations do |t|
      t.integer :user_a_id
      t.integer :user_b_id

      t.timestamps
    end
  end
end
