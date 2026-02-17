# frozen_string_literal: true

module Moderation
  class TransparencyController < ApplicationController
    before_action :set_cliq

    def show
      @rank_settings = Moderation.config.rank_settings(@cliq.rank_name)
      @active_moderators = @cliq.active_moderators.includes(:user)
      window_start = Moderation.config.transparency_window_days.days.ago
      @action_counts = ModerationAction.where(cliq: @cliq, created_at: window_start..).group(:action_type).count
      @recent_reports = @cliq.reports.where(created_at: window_start..).count
    end

    private

    def set_cliq
      @cliq = Cliq.find(params[:id])
    end
  end
end

