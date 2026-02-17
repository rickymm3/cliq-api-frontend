# app/controllers/followings_controller.rb
class FollowingsController < ApplicationController
  before_action :authenticate_user!

  # List all users the current user is following (for management)
  def index
    @followings = current_user.following
  end

  # Follow a user
  def create
    user_to_follow = User.find(params[:followed_id])
    current_user.follow(user_to_follow)
    redirect_back fallback_location: root_path, notice: "You are now following #{user_to_follow.profile.username}."
  end

  # Unfollow a user
  def destroy
    following = Following.find(params[:id])
    user_name = following.followed.profile.username
    following.destroy
    redirect_back fallback_location: root_path, notice: "You have unfollowed #{user_name}."
  end
end
