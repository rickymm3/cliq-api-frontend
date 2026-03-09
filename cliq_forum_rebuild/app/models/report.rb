class Report < ApplicationRecord
	belongs_to :cliq
	belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true, counter_cache: true

  after_create_commit :check_threshold

  validates :reason, presence: true

  private

  def check_threshold
    ReportThresholdChecker.call(self)
  end
end

