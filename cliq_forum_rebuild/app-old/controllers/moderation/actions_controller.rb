# frozen_string_literal: true

module Moderation
  class ActionsController < ApplicationController
    before_action :authenticate_user!

    def create
      @report = Report.find(action_params[:report_id])
      ensure_moderator_access!(@report.cliq)

      case action_params[:action_type]
      when "escalate"
        handle_escalation
      else
        handle_resolution(action_params[:action_type])
      end
    end

    private

    def handle_escalation
      target = @report.cliq.parent_cliq
      if target
        @report.escalate!(target)
        respond_success("Report escalated to #{target.name}.")
      else
        respond_failure("No parent cliq to escalate to.", :unprocessable_entity)
      end
    end

    def handle_resolution(action)
      note = action_params[:note].presence
      if note
        metadata = @report.metadata || {}
        metadata["resolution_note"] = note
        @report.update!(metadata: metadata)
      end

      @report.resolve!(actor: current_user, action: action.presence || "resolve")
      respond_success("Report handled.")
    rescue StandardError => e
      respond_failure(e.message, :unprocessable_entity)
    end

    def respond_success(message)
      respond_to do |format|
        format.html { redirect_back fallback_location: moderation_queue_path(@report.cliq), notice: message }
        format.turbo_stream do
          flash.now[:notice] = message
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "layouts/flash"),
            turbo_stream.remove(dom_id(@report))
          ]
        end
        format.json { render json: { ok: true }, status: :ok }
      end
    end

    def respond_failure(message, status)
      respond_to do |format|
        format.html { redirect_back fallback_location: moderation_queue_path(@report.cliq), alert: message }
        format.turbo_stream do
          flash.now[:alert] = message
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash"), status: status
        end
        format.json { render json: { ok: false, error: message }, status: status }
      end
    end

    def ensure_moderator_access!(cliq)
      authorized = current_user.moderator_roles.active.where(cliq: cliq).exists?
      raise ActionController::RoutingError, "Not Found" unless authorized
    end

    def action_params
      params.require(:action).permit(:report_id, :action_type, :note)
    end

    def dom_id(record)
      ActionView::RecordIdentifier.dom_id(record)
    end
  end
end

