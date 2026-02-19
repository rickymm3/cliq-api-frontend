class MergeProposalService
  def initialize(proposer, source_cliq_id, target_cliq_id, reason = nil)
    @proposer = proposer
    @source_cliq = Cliq.find(source_cliq_id)
    @target_cliq = Cliq.find(target_cliq_id)
    @reason = reason
  end

  def call
    ActiveRecord::Base.transaction do
      # 1. Calculate threshold
      # "10% of weekly unique visitors, min 5"
      weekly_visitors = @source_cliq.weekly_unique_visitors
      # Ensure threshold is at least 5
      threshold = [5, (weekly_visitors * 0.10).ceil].max
      
      # 2. Create the Proposal
      proposal = CliqMergeProposal.create!(
        source_cliq: @source_cliq,
        target_cliq: @target_cliq,
        proposer: @proposer,
        status: :proposal_phase,
        phase_1_expires_at: 1.week.from_now
      )

      post_content = "Merge Proposal: #{@source_cliq.name} -> #{@target_cliq.name}. Vote Yes/No. (Threshold: #{threshold} votes needed)"
      post_content += "\n\nReason: #{@reason}" if @reason.present?

      # 3. Create the Proposal Post
      Post.create!(
        title: "Merge Proposal: #{@source_cliq.name} -> #{@target_cliq.name}",
        # Embedding threshold in content for visibility since we don't store it yet
        content: post_content,
        user: @proposer,
        cliq: @source_cliq,
        kind: :merge_proposal,
        cliq_merge_proposal: proposal
      )

      # Ensure the proposal knows about the post for the return value
      proposal.reload
      proposal
    end
  rescue ActiveRecord::RecordInvalid => e
    # Return errors object designed to act like a model with errors
    OpenStruct.new(success?: false, errors: e.record.errors)
  end
end
