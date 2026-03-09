class PostDailyStat < ApplicationRecord
  belongs_to :post
  
  validates :date, presence: true, uniqueness: { scope: :post_id }
  validates :unique_visits_count, numericality: { greater_than_or_equal_to: 0 }
end
