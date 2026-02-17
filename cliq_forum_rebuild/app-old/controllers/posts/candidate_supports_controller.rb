# frozen_string_literal: true

module Posts
  class CandidateSupportsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_post

    def create
      return unless ensure_candidate_access

      support = CandidateSupport.new(
        user: current_user,
        cliq: @post.cliq,
        candidate_user: @post.user,
        post: @post,
        weight: support_weight
      )

      if support.save
        respond_success(:created)
      else
        respond_failure(support.errors.full_messages.to_sentence, :unprocessable_entity)
      end
    end

    def destroy
      return unless ensure_candidate_access

      support = CandidateSupport.find_by!(user: current_user, post: @post)
      support.destroy!
      respond_success(:ok)
    rescue ActiveRecord::RecordNotFound
      respond_failure("Support not found.", :not_found)
    end

    private

    def set_post
      @post = Post.find(params[:post_id])
    end

    def ensure_candidate_access
      unless @post.visibility_moderation?
        respond_failure("This post is not a moderator candidacy.", :not_found)
        return false
      end

      unless current_user.established_for_moderation?
        respond_failure("You are not eligible to support moderators.", :forbidden)
        return false
      end
      true
    end

    def respond_success(status)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@post, :support_button), partial: "moderation/support_button", locals: { post: @post, supporter: current_user }) }
        format.html { redirect_to post_support_redirect_target, notice: "Support recorded." }
        format.json { render json: { ok: true, support_count: @post.reload.moderation_supports_count }, status: status }
      end
    end

    def respond_failure(message, status)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: status
        end
        format.html { redirect_to post_support_redirect_target, alert: message }
        format.json { render json: { ok: false, error: message }, status: status }
      end
    end

    def post_support_redirect_target
      post_id_slug_post_path(post_id: @post.id, slug: @post.slug)
    end

    def support_weight
      return 1.0 unless Moderation.config.liquid_democracy_enabled?
      1.0 + ModerationDelegation.active.where(delegatee: current_user, cliq: @post.cliq).count
    end

    def dom_id(record, prefix)
      ActionView::RecordIdentifier.dom_id(record, prefix)
    end
  end
end
