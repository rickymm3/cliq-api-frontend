class CreatePostLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :post_links do |t|
      t.references :post, null: false, foreign_key: true
      t.string :lens_id # The lens identifier this link belongs to (e.g. "manga", "netflix")
      t.timestamps
    end
    add_index :post_links, [:post_id, :lens_id], unique: true
  end
end
