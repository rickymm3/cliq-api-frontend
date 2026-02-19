class CliqVisit < ApplicationRecord
  belongs_to :cliq

  # Log a visit efficiently
  def self.log_visit(cliq_id, visitor_ip, user_agent, user_id = nil)
    return unless cliq_id.present?

    # Generate a consistent hash for the visitor
    # combining IP and User Agent covers most "unique" definitions without cookies
    visitor_string = "#{visitor_ip}-#{user_agent}-#{Date.today}"
    hash = Digest::SHA256.hexdigest(visitor_string)[0..23]

    current_time = Time.current
    today = Date.today

    # Try to insert. If it fails due to unique constraint, we just ignore it (already visited).
    begin
      create(
        cliq_id: cliq_id,
        visitor_hash: hash,
        visited_on: today,
        user_id: user_id
      )
    rescue ActiveRecord::RecordNotUnique
      # Visitor already logged for today
      nil
    end
  end
end
