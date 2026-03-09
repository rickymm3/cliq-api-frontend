class PostVisit < ApplicationRecord
  belongs_to :post
  belongs_to :user, optional: true

  # Log a visit efficiently
  def self.log_visit(post_id, visitor_ip, user_agent, user_id = nil)
    return unless post_id.present?

    # Generate a consistent hash for the visitor
    # combining IP and User Agent covers most "unique" definitions without cookies
    visitor_string = "#{visitor_ip}-#{user_agent}-#{Date.today}"
    hash = Digest::SHA256.hexdigest(visitor_string)[0..23]

    today = Date.today

    # Try to insert. If it fails due to unique constraint, we just ignore it (already visited).
    begin
      create(
        post_id: post_id,
        visitor_hash: hash,
        visited_on: today,
        user_id: user_id
      )
      
      # If successful, increment daily unique stats
      stat = PostDailyStat.find_or_create_by(post_id: post_id, date: today)
      stat.increment!(:unique_visits_count)
      
    rescue ActiveRecord::RecordNotUnique
      # Already visited today by this visitor
    end
    
    # Increment raw hits regardless of uniqueness
    stat = PostDailyStat.find_or_create_by(post_id: post_id, date: today)
    stat.increment!(:raw_hits_count)
    
    # Also update post views count (denormalized - usually raw hits)
    Post.increment_counter(:views_count, post_id)
  end
end
