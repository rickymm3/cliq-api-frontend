class CreateReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :replies do |t|
      t.text :content
      t.integer :user_id
      t.integer :post_id
      t.integer :parent_reply_id

      t.timestamps
    end
  end
end
