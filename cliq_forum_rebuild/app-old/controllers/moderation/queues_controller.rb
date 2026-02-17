# frozen_string_literal: true

module Moderation
  class QueuesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_cliq
    before_action :ensure_moderator!

    def show
      @pending_reports = @cliq.reports.active.order(:created_at)
      @active_moderators = @cliq.active_moderators.includes(:user)
      @support_capacity = @cliq.support_capacity_per_user

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    private

    def set_cliq
      @cliq = Cliq.find(params[:id])
    end

    def ensure_moderator!
      authorized = current_user.moderator_roles.active.where(cliq: @cliq).exists?
      return if authorized

      redirect_to cliq_path(@cliq), alert: "You do not have access to this moderation queue."
    end
  end
end

