class CreatePostSignals < ActiveRecord::Migration[8.0]
  def change
    create_table :post_signals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :post_signals, [:user_id, :post_id], unique: true
  end
end
