class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  # PATCH /subscriptions/:id/toggle
  def toggle
    @subscription = current_user.subscriptions.find(params[:id])
    @subscription.update!(enabled: !@subscription.enabled)
    reload_subscription_state!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          view_context.dom_id(@subscription, :pill),
          partial: "profiles/subscription_pill",
          locals: { subscription: @subscription }
        )
      end
      format.html { redirect_to profile_path(current_user.profile), status: :see_other }
    end
  end

  def create
    @cliq = Cliq.find(params[:cliq_id])

    if (ancestor = current_user.subscribed_ancestor_for(@cliq))
      reload_subscription_state!
      respond_subscribe_button(@cliq)   # 🔸 no frame param
      return
    end

    @subscription = current_user.subscriptions.find_or_initialize_by(cliq: @cliq)
    if @subscription.persisted? || @subscription.save
      child_ids = current_user.descendant_ids_for(@cliq)
      current_user.subscriptions.where(cliq_id: child_ids).delete_all if child_ids.any?
      reload_subscription_state!
      respond_subscribe_button(@cliq)   # 🔸 no frame param
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @subscription = current_user.subscriptions.find(params[:id]) rescue find_subscription!
    render_cliq = params[:target_cliq_id].present? ? Cliq.find(params[:target_cliq_id]) : @subscription.cliq

    if @subscription.destroy
      reload_subscription_state!

      if params[:context] == "profile_row"
        render turbo_stream: turbo_stream.replace(
          view_context.dom_id(@subscription),
          partial: "subscriptions/row_removed",
          locals: { frame_id: view_context.dom_id(@subscription) }
        )
      else
        respond_subscribe_button(render_cliq)   # 🔸 no frame param
      end
    else
      head :unprocessable_entity
    end
  end


  # GET /subscriptions/:id/confirm
  def confirm
    @subscription = current_user.subscriptions.find(params[:id])
    render partial: "subscriptions/confirm_row", locals: { subscription: @subscription }, status: :ok
  end

  # GET /subscriptions/:id/row
  def row
    @subscription = current_user.subscriptions.find(params[:id])
    render partial: "subscriptions/row", locals: { subscription: @subscription }, status: :ok
  end

  private

  def parent_group_for(cliq)
    cliq.ancestors.any? ? cliq.ancestors.first : cliq
  end

  def find_subscription!
    if params[:id].present?
      current_user.subscriptions.find(params[:id])
    else
      cliq = Cliq.find(params[:cliq_id])
      current_user.subscriptions.find_by!(cliq: cliq)
    end
  end

  # 🔑 the responder: HTML for frame requests, Turbo Stream otherwise
  def respond_subscribe_button(cliq, frame_id = nil)
    frame_target = request.headers["Turbo-Frame"].presence
    frame_id   ||= frame_target || view_context.dom_id(cliq, :subscribe_button)

    if frame_target
      # Frame-targeted submit → return HTML (updated <turbo-frame id="...">...</turbo-frame>)
      render partial: "cliqs/subscribe_button",
            locals:  { cliq: cliq, frame_id: frame_id },
            formats: :html,
            content_type: "text/html",
            status: :ok
    else
      # Non-frame → send a turbo stream replace (works on full page)
      render turbo_stream: turbo_stream.replace(
        frame_id,
        partial: "cliqs/subscribe_button",
        locals:  { cliq: cliq, frame_id: frame_id }
      )
    end
  end


  def reload_subscription_state!
    current_user.reload
    current_user.subscriptions.reset
  end
end
