class ReportThresholdChecker
  # Logic: If reports count exceeds 15% of unique views (min 3 reports), mark as contentious (hidden from public)
  REPORT_RATIO_THRESHOLD = 0.15
  MIN_REPORTS_THRESHOLD = 3

  def self.call(report)
    return unless report.respond_to?(:reporter)
    
    reportable = report.reportable
    return unless reportable.respond_to?(:reports_count)
    
    # Reload to ensure count is fresh
    reportable.reload
    
    # Logic 1: Admin Override
    if report.reporter&.admin?
      mark_contentious!(reportable)
      return
    end

    # Determine unique audience size
    if reportable.is_a?(Post)
      audience_size = [reportable.post_daily_stats.sum(:unique_visits_count), 1].max
    elsif reportable.is_a?(Reply)
      # For replies, use parent post views as baseline for exposure
      audience_size = [reportable.post.views_count, 1].max
    else
      audience_size = 1
    end
    
    # Calculate Ratio
    ratio = reportable.reports_count.to_f / audience_size
    
    Rails.logger.info "Checking Threshold for #{reportable.class} ##{reportable.id}: Reports=#{reportable.reports_count}, Audience=#{audience_size}, Ratio=#{ratio}"

    if reportable.reports_count >= MIN_REPORTS_THRESHOLD && ratio > REPORT_RATIO_THRESHOLD
      mark_contentious!(reportable)
    end
  end

  private

  def self.mark_contentious!(reportable)
    if reportable.respond_to?(:status_contentious!) && !reportable.status_contentious?
      # Use update_columns to bypass updated_at timestamp change (prevents bumping)
      # status: 1 corresponds to 'contentious' in post.rb enum
      reportable.update_columns(status: 1, hidden_at: Time.current)
      Rails.logger.info "Marked #{reportable.class} ##{reportable.id} as CONTENTIOUS"
    end
  end
end

