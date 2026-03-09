class AddKindToCliqAllianceProposals < ActiveRecord::Migration[8.0]
  def change
    add_column :cliq_alliance_proposals, :kind, :integer, default: 0, null: false
  end
end
