class HeatCalculator
  # Heat formula: (views * view_weight + replies * reply_weight) / (age_hours + 2) ^ gravity
  VIEW_WEIGHT = 0.1
  REPLY_WEIGHT = 5.0
  GRAVITY = 1.8

  def self.calculate(post)
    return 0 if post.views_count.zero? && post.replies_count.zero?

    age_hours = ((Time.current - post.created_at) / 3600).ceil + 1

    numerator = (post.views_count * VIEW_WEIGHT) + (post.replies_count * REPLY_WEIGHT)
    denominator = (age_hours + 2) ** GRAVITY

    heat = numerator / denominator
    post.update(heat_score: heat)
    heat
  end

  def self.recalculate_all
    Post.find_each { |post| calculate(post) }
  end
end
