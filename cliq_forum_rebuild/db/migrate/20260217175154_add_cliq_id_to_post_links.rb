class AddCliqIdToPostLinks < ActiveRecord::Migration[8.0]
  def change
    add_reference :post_links, :cliq, null: false, foreign_key: true
  end
end
