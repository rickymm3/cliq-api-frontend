class Api::FollowedUsersController < Api::BaseController
  before_action :authenticate_api_user!

  def create
    user = User.find(follow_params[:followed_id])
    if current_user.active_followed_users.create(followed_id: user.id)
      render json: { status: 'success', message: "You are now following #{user.email}" }, status: :created
    else
      render json: { error: 'Unable to follow user' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  rescue ActiveRecord::RecordNotUnique
    render json: { error: 'Already following this user' }, status: :unprocessable_entity
  end

  def destroy
    # We allow deleting by the User ID of the person being followed
    # logic: DELETE /api/followed_users/:id -> unfollow user with ID :id
    user = User.find(params[:id])
    relationship = current_user.active_followed_users.find_by(followed_id: user.id)
    
    if relationship
      relationship.destroy
      head :no_content
    else
      render json: { error: 'Relationship not found' }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    # If user not found, maybe they sent the relationship ID? 
    # For now, stick to User ID as the identifier for simplicity in Frontend
    render json: { error: 'User not found' }, status: :not_found
  end

  private

  def follow_params
    params.require(:followed_user).permit(:followed_id)
  end
end
