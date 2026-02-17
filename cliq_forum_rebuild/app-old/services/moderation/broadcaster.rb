# frozen_string_literal: true

require "action_view/record_identifier"

module Moderation
  module Broadcaster
    module_function

    def support_updated!(post)
      return unless post.present?

      Turbo::StreamsChannel.broadcast_replace_to(
        support_stream_name(post.cliq),
        target: ActionView::RecordIdentifier.dom_id(post, :support_count),
        partial: "moderation/support_count",
        locals: { post: post }
      )
    rescue StandardError => e
      Rails.logger.error("Moderation::Broadcaster failed to broadcast support update: #{e.message}")
    end

    def queue_updated!(cliq)
      return unless cliq.present?

      Turbo::StreamsChannel.broadcast_replace_to(
        queue_stream_name(cliq),
        target: "moderation_queue",
        partial: "moderation/queues/queue",
        locals: { cliq: cliq, reports: cliq.pending_reports }
      )
    rescue StandardError => e
      Rails.logger.error("Moderation::Broadcaster failed to broadcast queue update: #{e.message}")
    end

    def support_stream_name(cliq)
      "cliq_#{cliq.id}_candidate_supports"
    end

    def queue_stream_name(cliq)
      "cliq_#{cliq.id}_moderation_queue"
    end
  end
end
