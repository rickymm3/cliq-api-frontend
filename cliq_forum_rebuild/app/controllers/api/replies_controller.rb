module Api
  class RepliesController < BaseController
    before_action :authenticate_api_user!, except: [:index, :show]
    before_action :set_post, only: [:index, :create]
    before_action :set_reply, only: [:show, :update, :destroy]
    before_action :authorize_reply_owner, only: [:update, :destroy]

    # GET /api/posts/:post_id/replies
    def index
      @replies = @post.replies.includes(:user, parent_reply: :user, child_replies: :user).order(created_at: :asc)
      
      render json: {
        status: "success",
        data: @replies.map { |reply| reply_json(reply) }
      }
    end

    # POST /api/posts/:post_id/replies
    def create
      @reply = @post.replies.build(reply_params)
      @reply.user = current_user

      if @reply.save
        render json: {
          status: "success",
          data: reply_json(@reply)
        }, status: :created
      else
        render json: {
          status: "error",
          errors: @reply.errors
        }, status: :unprocessable_entity
      end
    end

    def show
      render json: {
        status: "success",
        data: reply_json(@reply)
      }
    end

    def update
      if @reply.update(reply_params)
        render json: {
          status: "success",
          data: reply_json(@reply)
        }
      else
        render json: {
          status: "error",
          errors: @reply.errors
        }, status: :unprocessable_entity
      end
    end

    def destroy
      if @reply.update(deleted_at: Time.current)
        render json: { 
          status: "success", 
          message: "Reply deleted",
          data: reply_json(@reply)
        }
      else
        Rails.logger.error("Reply soft-delete failed: #{@reply.errors.full_messages}")
        render json: { status: "error", errors: @reply.errors }, status: :unprocessable_entity
      end
    end

    private

    def set_post
      @post = Post.find(params[:post_id])
    end

    def set_reply
      @reply = Reply.find(params[:id])
    end

    def reply_params
      params.require(:reply).permit(:content, :parent_reply_id)
    end

    def authorize_reply_owner
      unless @reply.user_id == current_user.id
        render json: { status: "error", message: "Unauthorized" }, status: :unauthorized
      end
    end

    def reply_json(reply)
      is_deleted = reply.deleted_at.present?
      
      content_display = is_deleted ? "[Post deleted]" : reply.content.to_s
      
      data = {
        id: reply.id,
        content: content_display,
        is_deleted: is_deleted,
        created_at: reply.created_at,
        updated_at: reply.updated_at,
        parent_reply_id: reply.parent_reply_id,
        user: {
          id: reply.user.id,
          email: reply.user.email
        }
      }

      if reply.parent_reply
        data[:parent] = {
          id: reply.parent_reply.id,
          user_email: reply.parent_reply.user.email.split('@').first
        }
      end

      data[:children] = reply.child_replies.map do |child|
        {
          id: child.id,
          user_email: child.user.email.split('@').first
        }
      end

      data
    end
  end
end
