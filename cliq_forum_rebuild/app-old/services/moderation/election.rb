# frozen_string_literal: true

module Moderation
  class Election
    Candidate = Struct.new(:post, :user, :support_count, :eligibility, keyword_init: true)

    attr_reader :cliq, :config

    def initialize(cliq, config: Moderation.config)
      @cliq = cliq
      @config = config
    end

    def call
      seats = cliq.seats_for_rank
      return conclude_all if seats.zero?

      active_roles = cliq.moderator_roles.active.index_by(&:user_id)
      selected_candidates = pick_top_candidates(seats)

      retain_user_ids = []

      selected_candidates.each do |candidate|
        retain_user_ids << candidate.user.id
        role = active_roles[candidate.user.id]
        if role
          role.update!(seated_supports_count: candidate.support_count)
        else
          role = cliq.moderator_roles.create!(
            user: candidate.user,
            started_at: Time.current,
            status: "active",
            seated_supports_count: candidate.support_count
          )
          log_role_change("seat_awarded", role, candidate.support_count)
        end
      end

      conclude_inactive(active_roles.keys - retain_user_ids)
    end

    private

    def conclude_all
      cliq.moderator_roles.active.find_each do |role|
        role.conclude!(ended_at: Time.current)
      end
    end

    def conclude_inactive(user_ids)
      return if user_ids.blank?
      cliq.moderator_roles.active.where(user_id: user_ids).find_each do |role|
        role.conclude!(ended_at: Time.current)
        log_role_change("seat_removed", role, role.seated_supports_count)
      end
    end

    def pick_top_candidates(seats)
      candidates = moderation_candidates.select { |candidate| candidate.eligibility.established? }
      candidates.sort! do |a, b|
        support_cmp = b.support_count <=> a.support_count
        next support_cmp unless support_cmp.zero?

        age_cmp = a.user.created_at <=> b.user.created_at
        next age_cmp unless age_cmp.zero?

        b.eligibility.activity_score <=> a.eligibility.activity_score
      end

      candidates.first(seats)
    end

    def moderation_candidates
      cliq.posts.moderation_posts.includes(:user).map do |post|
        eligibility = Moderation::Eligibility.new(post.user)
        Candidate.new(
          post: post,
          user: post.user,
          support_count: post.moderation_supports_count,
          eligibility: eligibility
        )
      end
    end

    def log_role_change(event, role, supports)
      actor = system_actor(role.user)
      return unless actor

      ModerationAction.create!(
        actor: actor,
        cliq: cliq,
        action_type: event,
        subject: role.user,
        metadata: {
          moderator_role_id: role.id,
          supports: supports
        }
      )
    end

    def system_actor(preferred_user)
      User.find_by(email: Rails.configuration.x.cliq.dig(:moderation, :system_actor_email)) || preferred_user || User.first
    end
  end
end
