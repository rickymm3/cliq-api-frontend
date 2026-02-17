class RepliesController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_reply, only: [:show, :edit, :update, :destroy]
  before_action :set_post_for_new, only: [:new]
  before_action :set_post_for_create, only: [:create]

  def show
  end

  def new
    @parent_reply = Reply.find_by(id: params[:parent_reply_id])
    @reply = Reply.new(post: @post, user: current_user, parent_reply: @parent_reply)

    # Block replying to a child reply (only top-level replies can be replied to)
    if @parent_reply&.parent_reply_id.present?
      frame_id = params[:frame_id].presence || "new_reply"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            frame_id,
            partial: "replies/locked_reply_slot",
            locals: { parent: @parent_reply, message: "You can only reply directly to a top-level reply." }
          )
        end
        format.html { redirect_to post_path(@post), alert: "You can only reply directly to a top-level reply." }
      end
      return
    end

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    @reply = Reply.new(reply_params)
    @reply.user = current_user

    if @reply.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to post_path(@reply.post), notice: "Reply was successfully created." }
      end
    else
      frame_id = params[:frame_id].presence ||
                 (@reply.parent_reply_id ? "reply_form_#{@reply.parent_reply_id}" : "new_reply")

      parent = @reply.parent_reply || Reply.find_by(id: @reply.parent_reply_id)
      is_depth_error = @reply.errors.full_messages.any? { |m| m =~ /only reply to a top-level reply/i }

      respond_to do |format|
        if parent && is_depth_error
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              frame_id,
              partial: "replies/locked_reply_slot",
              locals: { parent: parent, message: "You can only reply directly to a top-level reply." }
            ), status: :unprocessable_entity
          end
          format.html { redirect_to post_path(@reply.post), alert: "You can only reply directly to a top-level reply." }
        else
          format.turbo_stream { render :new, status: :unprocessable_entity }
          format.html        { render :new, status: :unprocessable_entity }
        end
      end
    end
  end

  def edit
  end

  def update
    if @reply.update(reply_params)
      redirect_to post_path(@reply.post), notice: "Reply was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = @reply.post
    @reply.destroy
    redirect_to post_path(post), notice: "Reply was successfully destroyed."
  end

  private

  def set_reply
    @reply = Reply.find(params[:id])
  end

  def set_post_for_new
    key = params[:post_id]
    @post = Post.find_by(slug: key) || Post.find_by(id: key)
  end

  def set_post_for_create
    @post = Post.find(reply_params[:post_id])
  end

  def reply_params
    params.require(:reply).permit(:content, :post_id, :parent_reply_id)
  end
end
