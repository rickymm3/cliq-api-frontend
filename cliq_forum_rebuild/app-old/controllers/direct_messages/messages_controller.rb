module DirectMessages
  class MessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_conversation

    def create
      @message = @conversation.messages.build(message_params)
      @message.sender = current_user
      @message.recipient = @conversation.other_participant(current_user)

      if @message.recipient.nil?
        redirect_to direct_messages_path, alert: "That conversation is no longer available."
        return
      end

      if @message.save
        redirect_to direct_message_path(@conversation)
      else
        @conversations =
          current_user
          .direct_message_conversations
          .includes(user_a: :profile, user_b: :profile)
          .ordered_by_recent_activity
        @conversation = @conversation.reload
        render "direct_messages/index", status: :unprocessable_entity
      end
    end

    private

    def set_conversation
      @conversation =
        current_user
        .direct_message_conversations
        .find(params[:direct_message_id])
    end

    def message_params
      params.require(:direct_message).permit(:body)
    end
  end
end
