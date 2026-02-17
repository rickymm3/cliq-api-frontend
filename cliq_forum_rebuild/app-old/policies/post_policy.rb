# app/policies/post_policy.rb
class PostPolicy < ApplicationPolicy
  # The record here is a Post object
  # The user is the current_user from Devise (or however authentication is handled)

  def edit?
    # Example logic: Only the post's author or an admin can edit
    user_is_author? || user_is_admin?
  end

  def update?
    # Typically same as edit
    edit?
  end

  def destroy?
    # Typically only the author or admin can destroy
    user_is_author? || user_is_admin?
  end

  private

  def user_is_author?
    user.present? && user == record.user
  end

  def user_is_admin?
    user.present? && user.role_admin?
  end
end
