class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.integer :reporter_id
      t.integer :cliq_id
      t.integer :post_id
      t.string :reason
      t.integer :status

      t.timestamps
    end
  end
end
