class Report < ApplicationRecord
	belongs_to :cliq
	belongs_to :reporter, class_name: "User"
  belongs_to :post, counter_cache: true

  after_create :check_post_threshold

  private

  def check_post_threshold
    # Logic: If reports count exceeds 10% of views (min 3 reports), hide post
    safe_views = [post.views_count, 1].max
    ratio = post.reports_count.to_f / safe_views

    if post.reports_count >= 3 && ratio > 0.1
      post.hidden!
    end
  end
end
