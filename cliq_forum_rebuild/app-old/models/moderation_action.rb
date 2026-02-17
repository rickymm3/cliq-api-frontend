# frozen_string_literal: true

class ModerationAction < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :cliq
  belongs_to :subject, polymorphic: true
  belongs_to :report, optional: true

  validates :action_type, presence: true
end

