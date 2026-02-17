class Users::SessionsController < Devise::SessionsController
  respond_to :html, :turbo_stream

  private

  def respond_with(resource, _opts = {})
    if request.format.turbo_stream? && resource.respond_to?(:errors) && resource.errors.empty?
      redirect_to(after_sign_in_path_for(resource), status: :see_other)
    else
      super
    end
  end

  def respond_to_on_destroy
    if request.format.turbo_stream?
      redirect_to(after_sign_out_path_for(resource_name), status: :see_other)
    else
      super
    end
  end
end
