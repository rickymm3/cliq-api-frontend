# app/controllers/followed_users_controller.rb
class FollowedUsersController < ApplicationController
  before_action :authenticate_user!

  # List all users that current_user follows
  def index
    @profile = current_user.profile
    @owner_viewing = true
    @section = :following
    @followed_users = current_user.followed_users.includes(:profile)
  end

  # Follow a user (called from a profile or carrot button)
  def create
    # Use User.find instead of User.friendly.find since FriendlyId is removed from the User model
    @user = User.find(params[:user_id])
    current_user.follow(@user)
    respond_to do |format|
      format.html { redirect_to profile_path(@user.profile), notice: "You are now following #{@user.profile.username}." }
      format.turbo_stream
    end
  end

  # Unfollow a user
  def destroy
    @user = User.find(params[:user_id])
    current_user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_to profile_path(@user.profile), notice: "You have unfollowed #{@user.profile.username}." }
      format.turbo_stream
    end
  end
end
