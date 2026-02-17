class CreateModeratorSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :moderator_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cliq, null: false, foreign_key: true

      t.timestamps
    end
    add_index :moderator_subscriptions, [:user_id, :cliq_id], unique: true
  end
end
