class DirectMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_conversations, only: %i[index show]

  def index
    @conversation = selected_conversation
    @message = DirectMessage.new if @conversation
    mark_conversation_as_read(@conversation)
    prepare_search_state
  end

  def show
    @conversation = @conversations.find(params[:id])
    @message = DirectMessage.new
    mark_conversation_as_read(@conversation)
    prepare_search_state

    render :index
  end

  def create
    recipient = resolve_recipient
    if recipient.nil?
      redirect_to direct_messages_path, alert: "Unable to find that user."
      return
    end

    if recipient.id == current_user.id
      redirect_to direct_messages_path, alert: "You cannot start a conversation with yourself."
      return
    end

    conversation = DirectMessageConversation.find_or_create_between!(current_user, recipient)

    respond_to do |format|
      format.turbo_stream do
        load_conversations
        @conversation = conversation
        @message = DirectMessage.new
        mark_conversation_as_read(@conversation)

        render turbo_stream: [
          turbo_stream.replace(
            "direct-message-conversations",
            render_to_string(
              partial: "direct_messages/conversation_list_wrapper",
              formats: [:html],
              locals: {
                conversations: @conversations,
                active_conversation: @conversation
              }
            )
          ),
          turbo_stream.replace(
            "direct-message-conversation",
            render_to_string(
              partial: "direct_messages/conversation_wrapper",
              formats: [:html],
              locals: {
                conversation: @conversation,
                message: @message
              }
            )
          )
        ]
      end

      format.html do
        redirect_to direct_message_path(conversation)
      end
    end
  end

  def search
    @query = search_params[:q].to_s.strip

    if @query.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "direct-message-search-results",
            partial: "direct_messages/no_results"
          )
        end
        format.html { head :ok }
      end
      return
    end

    @users = search_users(@query)

    respond_to do |format|
      format.turbo_stream
      format.html { render partial: "direct_messages/search_results" }
    end
  end

  private

  def load_conversations
    @conversations =
      current_user
      .direct_message_conversations
      .includes(user_a: :profile, user_b: :profile)
      .ordered_by_recent_activity
  end

  def selected_conversation
    return @conversations.find_by(id: params[:conversation_id]) if params[:conversation_id].present?
    @conversations.first
  end

  def mark_conversation_as_read(conversation)
    return unless conversation

    conversation
      .messages
      .for_recipient(current_user)
      .unread
      .update_all(read_at: Time.current)
  end

  def resolve_recipient
    if params[:user_id].present?
      User.find_by(id: params[:user_id])
    elsif params[:username].present?
      profile = Profile.find_by("LOWER(username) = ?", params[:username].to_s.downcase)
      profile&.user
    else
      nil
    end
  end

  def prepare_search_state
    @users ||= User.none
    @query ||= nil
  end

  def search_params
    params.permit(:q)
  end

  def search_users(query)
    User
      .joins(:profile)
      .where.not(id: current_user.id)
      .where("profiles.username ILIKE ?", "%#{query}%")
      .includes(:profile)
      .order("profiles.username")
      .limit(10)
  end
end
