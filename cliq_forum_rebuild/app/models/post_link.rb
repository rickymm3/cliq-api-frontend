class PostLink < ApplicationRecord
  belongs_to :post
  belongs_to :cliq
  
  # A post link connects a post to a specific "lens" (context),
  # allowing it to appear in Alias Cliqs that define this lens.
  
  validates :lens_id, presence: true
  validates :post_id, uniqueness: { scope: [:cliq_id, :lens_id] }
end
