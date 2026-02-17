class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.integer :recipient_id
      t.integer :actor_id
      t.string :notifiable_type
      t.integer :notifiable_id
      t.datetime :read_at

      t.timestamps
    end
  end
end
