module Api
  module Admin
    class DashboardController < Api::BaseController
      before_action :authenticate_api_user!
      before_action :require_admin!

      def index
        merge_proposals = CliqMergeProposal.where(status: [:proposal_phase, :verification_phase])
        alliance_proposals = CliqAllianceProposal.where(status: :proposal_phase)
        
        # Include relevant details for the dashboard
        render json: {
          status: "success",
          data: {
            merge_proposals: merge_proposals.as_json(include: [:source_cliq, :target_cliq, :proposer, :post]),
            alliance_proposals: alliance_proposals.as_json(include: [:source_cliq, :target_cliq, :proposer, :post]),
            stats: {
              users_count: User.count,
              cliqs_count: Cliq.count,
              posts_count: Post.count
            }
          }
        }
      end

      private

      def require_admin!
        unless current_user.admin?
          render json: { status: "error", message: "Admin access required" }, status: :forbidden
        end
      end
    end
  end
end
