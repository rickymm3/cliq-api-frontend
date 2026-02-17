class CreateCliqs < ActiveRecord::Migration[8.0]
  def change
    create_table :cliqs do |t|
      t.string :name
      t.integer :parent_cliq_id
      t.integer :rank
      t.string :slug

      t.timestamps
    end
  end
end
