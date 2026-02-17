class CreateDirectMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :direct_messages do |t|
      t.text :body
      t.integer :sender_id
      t.integer :recipient_id
      t.integer :conversation_id
      t.datetime :read_at

      t.timestamps
    end
  end
end
