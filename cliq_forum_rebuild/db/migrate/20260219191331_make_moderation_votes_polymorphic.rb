class MakeModerationVotesPolymorphic < ActiveRecord::Migration[8.0]
  def change
    remove_reference :moderation_votes, :post, index: true, foreign_key: true
    add_reference :moderation_votes, :voteable, polymorphic: true, index: true
  end
end
