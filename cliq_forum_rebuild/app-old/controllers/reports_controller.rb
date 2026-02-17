# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    return unless ensure_reporting_allowed

    reportable = locate_reportable
    cliq = resolve_cliq(reportable)

    @report = Report.new(
      reportable: reportable,
      cliq: cliq,
      reporter: current_user,
      reason: report_params[:reason],
      note: report_params[:note],
      metadata: { source: params[:source], referer: request.referer }
    )

    if @report.save
      respond_to do |format|
        format.html { redirect_back fallback_location: post_redirect_target(reportable), notice: "Report submitted." }
        format.turbo_stream do
          flash.now[:notice] = "Report submitted."
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: :ok
        end
        format.json { render json: { ok: true, id: @report.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: post_redirect_target(reportable), alert: @report.errors.full_messages.to_sentence }
        format.turbo_stream do
          flash.now[:alert] = @report.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: :unprocessable_entity
        end
        format.json { render json: { ok: false, errors: @report.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @report = Report.find(params[:id])
    action = params.require(:report).permit(:state, :note, :resolution_action)[:resolution_action]
    ensure_moderator_access!(@report.cliq)

    if params.dig(:report, :note).present?
      metadata = @report.metadata || {}
      metadata["resolution_note"] = params[:report][:note]
      @report.update!(metadata: metadata)
    end
    @report.resolve!(actor: current_user, action: action.presence || "resolve")

    respond_to do |format|
      format.html { redirect_back fallback_location: moderation_queue_path(@report.cliq), notice: "Report updated." }
      format.json { render json: { ok: true } }
    end
  end

  private

  def ensure_reporting_allowed
    unless current_user.established_for_moderation?
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Only established accounts may file reports." }
        format.turbo_stream do
          flash.now[:alert] = "Only established accounts may file reports."
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: :forbidden
        end
        format.json { render json: { ok: false, error: "not_eligible" }, status: :forbidden }
      end
      return false
    end

    limiter = Moderation::RateLimiter.new(current_user)
    return true if limiter.report_within_limit?

    message = "You have reached the reporting limit. Please try again later."
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: message }
      format.turbo_stream do
        flash.now[:alert] = message
        render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: :too_many_requests
      end
      format.json { render json: { ok: false, error: "rate_limited" }, status: :too_many_requests }
    end
    false
  end

  def locate_reportable
    type = report_params[:reportable_type]
    id = report_params[:reportable_id]
    case type
    when "Post"
      Post.find(id)
    when "Reply"
      Reply.find(id)
    else
      raise ActionController::BadRequest, "Unsupported reportable type"
    end
  end

  def resolve_cliq(reportable)
    case reportable
    when Post
      reportable.cliq
    when Reply
      reportable.post&.cliq
    end
  end

  def post_redirect_target(reportable)
    post = case reportable
           when Post then reportable
           when Reply then reportable.post
           end
    post ? post_id_slug_post_path(post_id: post.id, slug: post.slug) : root_path
  end

  def ensure_moderator_access!(cliq)
    return if current_user&.moderator_roles&.active&.where(cliq: cliq).exists?

    raise ActionController::RoutingError, "Not Found"
  end

  def report_params
    params.require(:report).permit(:reportable_type, :reportable_id, :reason, :note)
  end
end
