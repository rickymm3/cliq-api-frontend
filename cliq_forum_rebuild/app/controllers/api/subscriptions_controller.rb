class Api::SubscriptionsController < ApplicationController
  def index
    subscriptions = Subscription.all
    render json: subscriptions
  end

  def show
    subscription = Subscription.find(params[:id])
    render json: subscription
  end

  def create
    subscription = Subscription.new(subscription_params)
    if subscription.save
      render json: subscription, status: :created
    else
      render json: subscription.errors, status: :unprocessable_entity
    end
  end

  def update
    subscription = Subscription.find(params[:id])
    if subscription.update(subscription_params)
      render json: subscription
    else
      render json: subscription.errors, status: :unprocessable_entity
    end
  end

  def destroy
    subscription = Subscription.find(params[:id])
    subscription.destroy
    head :no_content
  end

  private

  def subscription_params
    params.require(:subscription).permit(:user_id, :cliq_id)
  end
end
