class CreateModeratorRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :moderator_roles do |t|
      t.integer :user_id
      t.integer :cliq_id
      t.integer :role_type

      t.timestamps
    end
  end
end
