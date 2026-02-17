# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    scope = current_user.notifications.order(created_at: :desc)
    @pagy, @notifications = pagy(scope, items: 20)
    @unread_count = current_user.notifications.unread.count
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: notifications_path
  end

  def update
    notification = current_user.notifications.find(params[:id])
    notification.update!(read_at: Time.current)
    redirect_to notification_target_path(notification)
  end

  private

  def notification_target_path(n)
    case n.notifiable
    when Post
      post_id_slug_post_path(post_id: n.notifiable.id, slug: n.notifiable.slug)
    else
      root_path
    end
  end
end
