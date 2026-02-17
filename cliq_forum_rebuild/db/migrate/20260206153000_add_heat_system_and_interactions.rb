class AddHeatSystemAndInteractions < ActiveRecord::Migration[8.0]
  def change
    # Heat System Columns for Posts
    add_column :posts, :heat_score, :float, default: 0.0
    add_column :posts, :views_count, :integer, default: 0
    add_column :posts, :replies_count, :integer, default: 0
    
    add_index :posts, :heat_score

    # User Preferences (Like/Dislike for curation)
    create_table :post_interactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :preference, default: 0, null: false # 0: neutral, 1: like, 2: dislike

      t.timestamps
    end
    
    add_index :post_interactions, [:user_id, :post_id], unique: true
  end
end
