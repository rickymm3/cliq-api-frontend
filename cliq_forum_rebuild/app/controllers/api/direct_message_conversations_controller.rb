class Api::DirectMessageConversationsController < ApplicationController
  def index
    conversations = DirectMessageConversation.all
    render json: conversations
  end

  def show
    conversation = DirectMessageConversation.find(params[:id])
    render json: conversation
  end

  def create
    conversation = DirectMessageConversation.new(conversation_params)
    if conversation.save
      render json: conversation, status: :created
    else
      render json: conversation.errors, status: :unprocessable_entity
    end
  end

  def update
    conversation = DirectMessageConversation.find(params[:id])
    if conversation.update(conversation_params)
      render json: conversation
    else
      render json: conversation.errors, status: :unprocessable_entity
    end
  end

  def destroy
    conversation = DirectMessageConversation.find(params[:id])
    conversation.destroy
    head :no_content
  end

  private

  def conversation_params
    params.require(:direct_message_conversation).permit(:user_a_id, :user_b_id)
  end
end
