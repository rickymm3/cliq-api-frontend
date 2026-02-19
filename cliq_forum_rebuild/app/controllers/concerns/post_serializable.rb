module PostSerializable
  extend ActiveSupport::Concern

  included do
    # Any necessary inclusions or setup
  end

  def serialize_post(post, current_user = nil)
    # Determine user interaction if user is logged in
    user_interaction = "neutral"
    is_signaled = false
    is_moderator = false
    
    if current_user
      interaction = post.post_interactions.find_by(user_id: current_user.id)
      user_interaction = interaction.preference if interaction
      is_signaled = post.post_signals.exists?(user_id: current_user.id)
      # Check if user is moderator for this post's cliq
      # Using exists? efficiently
      is_moderator = current_user.moderator_subscriptions.exists?(cliq_id: post.cliq_id)
    end

    cliq_data = {
      id: post.cliq.id,
      name: post.cliq.name,
      parent_cliq_id: post.cliq.parent_cliq_id
    }

    # Include parent cliq if it exists
    if post.cliq.parent_cliq
      cliq_data[:parent] = {
        id: post.cliq.parent_cliq.id,
        name: post.cliq.parent_cliq.name
      }
    end

    # Serialize ActionText content
    content_html = if post.content.present?
                     post.content.to_s
                   else
                     ""
                   end

    {
      id: post.id,
      slug: post.slug,
      title: post.title,
      content: content_html,
      content_json: post.content.body&.as_json || [], # Keep for robustness
      post_type: post.post_type,
      visibility: post.visibility,
      heat_score: post.heat_score,
      views_count: post.views_count,
      replies_count: post.replies_count,
      reports_count: post.respond_to?(:reports_count) ? post.reports_count : 0,
      is_moderator: is_moderator,
      user_interaction: user_interaction,
      is_signaled: is_signaled,
      user: {
        id: post.user.id,
        email: post.user.email
      },
      cliq: cliq_data,
      created_at: post.created_at,
      updated_at: post.updated_at,
      kind: post.kind,
      merge_proposal: post.cliq_merge_proposal.present? ? {
        id: post.cliq_merge_proposal.id,
        source_cliq: { id: post.cliq_merge_proposal.source_cliq.id, name: post.cliq_merge_proposal.source_cliq.name },
        target_cliq: { id: post.cliq_merge_proposal.target_cliq.id, name: post.cliq_merge_proposal.target_cliq.name },
        status: post.cliq_merge_proposal.status,
        yes_votes: post.cliq_merge_proposal.yes_votes,
        no_votes: post.cliq_merge_proposal.no_votes,
        phase_1_expires_at: post.cliq_merge_proposal.phase_1_expires_at,
        phase_2_expires_at: post.cliq_merge_proposal.phase_2_expires_at
      } : nil
    }
  end
end
