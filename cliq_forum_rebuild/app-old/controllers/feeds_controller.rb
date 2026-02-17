class FeedsController < ApplicationController
  before_action :authenticate_user!

  # GET /subscribed
  def subscribed
    # Start with enabled, de-duplicated subscriptions (parents dominate)
    effective_root_ids = current_user.effective_enabled_subscription_ids

    # Expand each effective root to include self + all descendants
    expanded_ids = []
    Cliq.where(id: effective_root_ids).includes(:child_cliqs).find_each do |cliq|
      expanded_ids.concat(cliq.self_and_descendant_ids)
    end
    expanded_ids.uniq!

    base = Post.visible_in_feeds.where(cliq_id: expanded_ids)
               .left_joins(:replies)
               .group('posts.id')
               .includes(:user, :cliq)
               .reorder(nil)

    # Same "latest activity" ordering as cliqs#show
    order_expr = 'GREATEST(posts.created_at, COALESCE(MAX(replies.created_at), posts.created_at)) DESC'
    @pagy, @posts = pagy(base.order(Arel.sql(order_expr)))
    @hot_preview = Post.hot.visible_in_feeds
                       .includes(:user, :cliq)
                       .order(heat_score: :desc, updated_at: :desc)
                       .limit(5)

    respond_to do |f|
      f.html
      f.turbo_stream
    end
  end

  private

  # (Kept for reference if needed elsewhere; current_user.effective_enabled_subscription_ids is used above)
  # Return cliq IDs such that if both a parent and a child are subscribed,
  # we keep only the ancestor (to avoid duplicate content).
  def effective_subscribed_cliq_ids_for(user)
    subs = user.subscribed_cliqs.includes(:parent_cliq) # direct subs
    return [] if subs.blank?

    sub_ids = subs.map(&:id).to_set

    effective = subs.reject do |c|
      p = c.parent_cliq
      covered = false
      while p
        if sub_ids.include?(p.id)
          covered = true
          break
        end
        p = p.parent_cliq
      end
      covered
    end

    effective.map(&:id)
  end
end
