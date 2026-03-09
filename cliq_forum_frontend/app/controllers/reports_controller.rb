class ReportsController < ApplicationController
  def create
    unless logged_in?
      render json: { error: "You must be logged in" }, status: :unauthorized
      return
    end

    # Construct API params
    api_params = {
      report: {
        reason: params[:reason],
        cliq_id: params[:cliq_id]
      }
    }

    if params[:post_id].present?
      api_params[:report][:reportable_type] = "Post"
      api_params[:report][:reportable_id] = params[:post_id]
    elsif params[:reply_id].present?
      api_params[:report][:reportable_type] = "Reply"
      api_params[:report][:reportable_id] = params[:reply_id]
    end

    response = api_post("reports", api_params)

    respond_to do |format|
      if response["id"] || (response["status"] && response["status"] == "created")
        format.turbo_stream do
          # 1. Close the modal by replacing it with the original hidden structural partial
          # AND clean up backdrop using the toast controller (updated in JS)
          streams = [
            turbo_stream.replace("reportModal", partial: "shared/report_modal"),
            turbo_stream.append("toast-container", partial: "shared/toast_success")
          ]
          
          # No longer need manual script injection as toast controller handles cleanup

          if params[:post_id].present?
            # Fetch updated post to reflect 'is_reported' status
            post_response = api_get("posts/#{params[:post_id]}")
            if post_response && post_response["data"]
              streams << turbo_stream.replace("post-#{params[:post_id]}", partial: "posts/post", locals: { post: post_response["data"] })
            end
          elsif params[:reply_id].present?
            # Fetch updated reply to reflect 'is_reported' status
            reply_response = api_get("replies/#{params[:reply_id]}")
            if reply_response && reply_response["data"]
              reply = reply_response["data"]
              # Replies partial needs cliq_id and post_id context
              c_id = params[:cliq_id] || reply["cliq_id"]
              p_id = params[:post_id] || reply["post_id"]
              streams << turbo_stream.replace("reply-#{params[:reply_id]}", partial: "replies/reply", locals: { reply: reply, cliq_id: c_id, post_id: p_id })
            end
          end
          
          render turbo_stream: streams
        end
        format.html { redirect_back fallback_location: root_path, notice: "Report submitted successfully." }
        format.json { render json: { status: "success" }, status: :created }
      else
        format.html { redirect_back fallback_location: root_path, alert: "Failed to submit report." }
        format.json { render json: { error: response }, status: :unprocessable_entity }
      end
    end
  end
end
