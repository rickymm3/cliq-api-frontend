class Api::DirectMessagesController < ApplicationController
  def index
    direct_messages = DirectMessage.all
    render json: direct_messages
  end

  def show
    direct_message = DirectMessage.find(params[:id])
    render json: direct_message
  end

  def create
    direct_message = DirectMessage.new(direct_message_params)
    if direct_message.save
      render json: direct_message, status: :created
    else
      render json: direct_message.errors, status: :unprocessable_entity
    end
  end

  def update
    direct_message = DirectMessage.find(params[:id])
    if direct_message.update(direct_message_params)
      render json: direct_message
    else
      render json: direct_message.errors, status: :unprocessable_entity
    end
  end

  def destroy
    direct_message = DirectMessage.find(params[:id])
    direct_message.destroy
    head :no_content
  end

  private

  def direct_message_params
    params.require(:direct_message).permit(:body, :sender_id, :recipient_id, :conversation_id, :read_at)
  end
end
