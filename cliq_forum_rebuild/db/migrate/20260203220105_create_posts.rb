class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
      t.integer :user_id
      t.integer :cliq_id
      t.integer :post_type
      t.integer :visibility
      t.datetime :hot_until

      t.timestamps
    end
  end
end
