# frozen_string_literal: true

class Report < ApplicationRecord
  STATES = {
    pending: "pending",
    escalated: "escalated",
    in_review: "in_review",
    resolved: "resolved"
  }.freeze

  belongs_to :reportable, polymorphic: true
  belongs_to :cliq
  belongs_to :reporter, class_name: "User"
  belongs_to :escalated_to_cliq, class_name: "Cliq", optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  scope :active, -> { where(state: [STATES[:pending], STATES[:escalated], STATES[:in_review]]) }
  scope :pending, -> { where(state: STATES[:pending]) }

  validates :reason, presence: true
  validates :state, inclusion: { in: STATES.values }

  before_validation :set_default_state, on: :create
  before_create :assign_initial_sla

  after_commit :trigger_queue_broadcast, on: [:create, :update]

  def escalate!(target_cliq)
    chain = metadata.fetch("escalation_chain", [])
    chain << { cliq_id: cliq_id, escalated_at: Time.current }

    update!(
      state: STATES[:escalated],
      cliq: target_cliq,
      escalated_to_cliq: target_cliq,
      escalated_at: Time.current,
      sla_expires_at: Moderation::SlaCalculator.next_expiry_for(target_cliq),
      metadata: metadata.merge("escalation_chain" => chain)
    )
  end

  def resolve!(actor:, action:)
    update!(
      state: STATES[:resolved],
      resolved_at: Time.current,
      resolved_by: actor
    )

    ModerationAction.create!(
      actor: actor,
      cliq: cliq,
      action_type: action,
      subject: reportable,
      report: self,
      notes: metadata.fetch("resolution_note", nil)
    )
  end

  def sla_expired?
    sla_expires_at.present? && Time.current >= sla_expires_at
  end

  private

  def set_default_state
    self.state ||= STATES[:pending]
  end

  def assign_initial_sla
    self.sla_expires_at = Moderation::SlaCalculator.next_expiry_for(cliq)
  end

  def trigger_queue_broadcast
    if saved_change_to_cliq_id?
      previous_id = saved_change_to_cliq_id.first
      if previous_id && (previous_cliq = Cliq.find_by(id: previous_id))
        Moderation::Broadcaster.queue_updated!(previous_cliq)
      end
    end

    Moderation::Broadcaster.queue_updated!(cliq)
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast queue update for report #{id}: #{e.message}")
  end
end
