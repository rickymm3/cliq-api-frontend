class RepliesController < ApplicationController
  include ApiClient
  before_action :require_login

  def edit
    @cliq_id = params[:cliq_id]
    @post_id = params[:post_id]
    @reply_id = params[:id]

    # Use shallow route for fetching a specific reply
    response = api_get("replies/#{@reply_id}")
    if response["status"] == "success"
      @reply = response["data"]
      render turbo_stream: turbo_stream.replace("reply-#{@reply['id']}", partial: "replies/edit_form", locals: { reply: @reply, cliq_id: @cliq_id, post_id: @post_id })
    else
      redirect_to cliq_post_path(@cliq_id, @post_id), alert: "Reply not found"
    end
  end

  def update
    @cliq_id = params[:cliq_id]
    @post_id = params[:post_id]
    @reply_id = params[:id]
    
    # Use shallow route for update
    response = api_put("replies/#{@reply_id}", { reply: reply_params })

    if response["status"] == "success"
      @reply = response["data"]
      render turbo_stream: turbo_stream.replace("reply-#{@reply['id']}", partial: "replies/reply", locals: { reply: @reply })
    else
      render turbo_stream: turbo_stream.replace("reply-#{@reply_id}", partial: "replies/edit_form", locals: { reply: params[:reply], cliq_id: @cliq_id, post_id: @post_id, error: "Update failed" })
    end
  end

  def destroy
    @cliq_id = params[:cliq_id]
    @post_id = params[:post_id]
    @reply_id = params[:id]
    
    # Use shallow route for delete
    response = api_delete("replies/#{@reply_id}")

    if response["status"] == "success"
      @reply = response["data"]
      render turbo_stream: turbo_stream.replace("reply-#{@reply['id']}", partial: "replies/reply", locals: { reply: @reply })
    else
       redirect_to cliq_post_path(@cliq_id, @post_id), alert: "Failed to delete"
    end
  end

  def create
    @cliq_id = params[:cliq_id]
    @post_id = params[:post_id]
    
    response = api_post("posts/#{@post_id}/replies", { reply: reply_params })

    if response["status"] == "success"
      @reply = response["data"]
      respond_to do |format|
        format.html { redirect_to cliq_post_path(@cliq_id, @post_id), notice: "Reply posted!", status: :see_other }
        format.turbo_stream
      end
    else
      redirect_to cliq_post_path(@cliq_id, @post_id), alert: "Failed to post reply.", status: :unprocessable_entity
    end
  end

  private

  def reply_params
    params.require(:reply).permit(:content, :parent_reply_id)
  end

  def require_login
    unless current_user
      redirect_to login_path, alert: "You must be logged in to reply."
    end
  end
end
