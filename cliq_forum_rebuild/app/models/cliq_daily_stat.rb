class CliqDailyStat < ApplicationRecord
  belongs_to :cliq
  
  validates :date, presence: true, uniqueness: { scope: :cliq_id }
  validates :unique_visits_count, numericality: { greater_than_or_equal_to: 0 }
end
