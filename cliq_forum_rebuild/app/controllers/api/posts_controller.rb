module Api
  class PostsController < BaseController
    include PostSerializable

    before_action :authenticate_api_user!, except: [:index, :show]
    before_action :authenticate_api_user_optional!, only: [:index, :show]
    before_action :set_cliq, only: [:index, :create]

    # GET /api/cliqs/:cliq_id/posts
    def index
      if @cliq
        # Determine scope: specific cliq or cliq + descendants
        if params[:exclude_children] == 'true' || params[:exclude_children] == '1'
          cliq_ids = [@cliq.id]
        else
          cliq_ids = [@cliq.id] + @cliq.descendants.pluck(:id)
        end
        scope = Post.where(cliq_id: cliq_ids)
      else
        # Global scope (e.g. for /api/posts?sort=recent)
        scope = Post.all
      end

      # Filter out moderation posts (handle logic for moderators)
      if current_user
        # Visible posts OR (Hidden posts AND (My Post OR I am Moderator))
        # Note: visibility 0: visible, 1: hidden, 2: removed
        
        # We use Arel for complex OR condition combined with scope
        posts = Post.arel_table
        
        visible = posts[:visibility].eq(0)
        hidden = posts[:visibility].eq(1)
        
        is_owner = posts[:user_id].eq(current_user.id)
        
        moderated_ids = current_user.moderated_cliq_ids
        is_moderator = moderated_ids.any? ? posts[:cliq_id].in(moderated_ids) : Arel::Nodes::False.new
        
        scope = scope.where(
          visible.or(
            hidden.and(
              is_owner.or(is_moderator)
            )
          )
        )
      else
        scope = scope.where(visibility: :visible)
      end

      # Apply sorting
      if params[:sort] == 'heat' || params[:sort] == 'top'
         scope = scope.order(heat_score: :desc)
      else
         scope = scope.order(updated_at: :desc)
      end

      # Pagination
      page = (params[:page] || 1).to_i
      per_page = (params[:limit] || 20).to_i
      offset = (page - 1) * per_page

      total_count = scope.count
      total_pages = (total_count.to_f / per_page).ceil
      
      @posts = scope.offset(offset).limit(per_page).includes(:user, :cliq)

      render json: {
        status: "success",
        data: @posts.map { |post| serialize_post(post, current_user) },
        pagination: {
          current_page: page,
          next_page: page < total_pages ? page + 1 : nil,
          total_pages: total_pages,
          total_count: total_count
        }
      }
    end

    # GET /api/posts/:id
    def show
      @post = Post.find(params[:id])
      
      # Increment views and recalculate heat
      @post.increment!(:views_count)
      @post.calculate_heat

      render json: {
        status: "success",
        data: serialize_post(@post, current_user)
      }
    end

    # POST /api/cliqs/:cliq_id/posts
    def create
      Rails.logger.info("=== POST CREATE DEBUG ===")
      Rails.logger.info("Authorization header: #{request.headers['Authorization'].inspect}")
      Rails.logger.info("HTTP_AUTHORIZATION header: #{request.headers['HTTP_AUTHORIZATION'].inspect}")
      Rails.logger.info("Current user: #{current_user.inspect}")
      
      @post = @cliq.posts.build(post_params)
      @post.user = current_user

      if @post.save
        render json: {
          status: "success",
          data: serialize_post(@post, current_user)
        }, status: :created
      else
        render json: {
          status: "error",
          errors: @post.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/posts/:id
    def update
      @post = Post.find(params[:id])
      authorize_post_owner

      if @post.update(post_params)
        render json: {
          status: "success",
          data: post_json(@post)
        }
      else
        render json: {
          status: "error",
          errors: @post.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/posts/:id
    def destroy
      @post = Post.find(params[:id])
      authorize_post_owner

      @post.destroy
      render json: { status: "success", message: "Post deleted" }
    end

    def signal
      @post = Post.find(params[:id])
      signal = current_user.post_signals.build(post: @post)
      
      if signal.save
        render json: { status: "success", message: "Post signaled" }
      else
        render json: { status: "error", message: signal.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    end

    def unsignal
      @post = Post.find(params[:id])
      signal = current_user.post_signals.find_by(post: @post)
      
      if signal&.destroy
        render json: { status: "success", message: "Signal removed" }
      else
        render json: { status: "error", message: "Signal not found" }, status: :not_found
      end
    end

    # POST /api/posts/:id/like
    def like
      @post = Post.find(params[:id])
      interaction = @post.post_interactions.find_or_initialize_by(user_id: current_user.id)
      interaction.update(preference: :like)

      render json: {
        status: "success",
        message: "Post liked",
        interaction: interaction.preference
      }
    end

    # POST /api/posts/:id/dislike
    def dislike
      @post = Post.find(params[:id])
      interaction = @post.post_interactions.find_or_initialize_by(user_id: current_user.id)
      interaction.update(preference: :dislike)

      render json: {
        status: "success",
        message: "Post disliked",
        interaction: interaction.preference
      }
    end

    # DELETE /api/posts/:id/unlike
    def unlike
      @post = Post.find(params[:id])
      interaction = @post.post_interactions.find_by(user_id: current_user.id)
      interaction&.update(preference: :neutral)

      render json: {
        status: "success",
        message: "Interaction removed",
        interaction: "neutral"
      }
    end

    private

    def set_cliq
      @cliq = Cliq.find(params[:cliq_id]) if params[:cliq_id].present?
    end

    def post_params
      post_params = params.require(:post).permit(:title, :content, :post_type, :visibility, :lead_image)
      # Convert post_type string to integer for enum validation
      post_params[:post_type] = post_params[:post_type].to_i if post_params[:post_type].present?
      post_params
    end

    def authorize_post_owner
      render json: { status: "error", message: "Unauthorized" }, status: :unauthorized unless @post.user_id == current_user.id
    end
  end
end
