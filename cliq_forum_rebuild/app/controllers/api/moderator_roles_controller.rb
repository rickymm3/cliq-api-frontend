class Api::ModeratorRolesController < ApplicationController
  def index
    moderator_roles = ModeratorRole.all
    render json: moderator_roles
  end

  def show
    moderator_role = ModeratorRole.find(params[:id])
    render json: moderator_role
  end

  def create
    moderator_role = ModeratorRole.new(moderator_role_params)
    if moderator_role.save
      render json: moderator_role, status: :created
    else
      render json: moderator_role.errors, status: :unprocessable_entity
    end
  end

  def update
    moderator_role = ModeratorRole.find(params[:id])
    if moderator_role.update(moderator_role_params)
      render json: moderator_role
    else
      render json: moderator_role.errors, status: :unprocessable_entity
    end
  end

  def destroy
    moderator_role = ModeratorRole.find(params[:id])
    moderator_role.destroy
    head :no_content
  end

  private

  def moderator_role_params
    params.require(:moderator_role).permit(:user_id, :cliq_id, :role_type)
  end
end
