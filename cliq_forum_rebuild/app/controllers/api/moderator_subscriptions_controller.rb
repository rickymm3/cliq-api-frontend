module Api
  class ModeratorSubscriptionsController < BaseController
    before_action :authenticate_api_user!
    
    def create
      cliq = Cliq.find(params[:cliq_id])
      subscription = current_user.moderator_subscriptions.build(cliq: cliq)
      
      if subscription.save
        render json: { status: "success", data: subscription }
      else
        render json: { status: "error", errors: subscription.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    def destroy
      # Find by cliq_id passed in parameters
      subscription = current_user.moderator_subscriptions.find_by(cliq_id: params[:cliq_id])
      
      if subscription
         subscription.destroy
         render json: { status: "success" }
      else
         render json: { status: "error", errors: ["Subscription not found"] }, status: :not_found
      end
    end
  end
end
