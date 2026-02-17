class AddUniqueIndexToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_index :subscriptions, [:user_id, :cliq_id], unique: true
  end
end
