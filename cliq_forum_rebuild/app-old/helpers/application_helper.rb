module ApplicationHelper
  include Pagy::Frontend

  def primary_sidebar_items
    [
      {
        key: :home,
        label: "My Feed",
        icon: "house-door-fill",
        path: subscribed_path,
        active: controller_name == "feeds" && action_name == "subscribed"
      },
      {
        key: :popular,
        label: "Popular",
        icon: "fire",
        path: popular_posts_path,
        active: controller_name == "posts" && action_name == "popular"
      },
      {
        key: :direct_messages,
        label: "Direct Messages",
        icon: "chat-dots",
        path: direct_messages_path,
        active: controller_name == "direct_messages",
        badge_count: (user_signed_in? ? current_user.unread_direct_messages_count : 0)
      }
    ]
  end
end
