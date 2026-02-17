class AddDefaultVisibilityToPosts < ActiveRecord::Migration[8.0]
  def change
    change_column_default :posts, :visibility, 0
    # Update any existing NULL visibility values to 0 (public_post)
    Post.update_all(visibility: 0) if Post.where(visibility: nil).exists?
  end
end
