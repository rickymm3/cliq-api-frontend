class CliqsController < ApplicationController
  before_action :set_cliq, only: %i[ show edit update destroy]
  before_action :authenticate_user!, only: [:new, :create]
  
  def index
    #change this to a cliq search page
    @cliq = Cliq.find_by(parent_cliq_id: nil)
    @pagy, @posts = pagy(Post.visible_in_feeds.ordered)
    respond_to do |format|
      format.html # For regular page load
      format.turbo_stream # For infinite scrolling via Turbo Stream
    end
  end

  # GET /cliqs/slug or /cliqs/1.json
  def show
    cliq_ids = @cliq.self_and_descendant_ids rescue [@cliq.id]
  
    @show_moderation_candidates = ActiveModel::Type::Boolean.new.cast(params[:show_moderation_candidates])

    base = Post.where(cliq_id: cliq_ids)
               .left_joins(:replies)        # bring in replies for MAX()
               .group('posts.id')           # needed for the aggregate
               .includes(:user, :cliq)
               .reorder(nil)                # IMPORTANT: clear any prior ORDERs (e.g., from scopes)

    base = if @show_moderation_candidates
             base.moderation_posts
           else
             base.visible_in_feeds
           end
 
    # Order by “latest activity” (newest reply OR post creation if no replies)
    order_expr = 'GREATEST(posts.created_at, COALESCE(MAX(replies.created_at), posts.created_at)) DESC'
 
    @pagy, @posts = pagy(base.order(Arel.sql(order_expr)))
  
    respond_to do |f|
      f.html
      f.turbo_stream
    end
  end
  
  # GET /cliqs/new
  def new
    @parent_cliq = Cliq.find_by(id: params[:parent_cliq_id])
    if @parent_cliq && !@parent_cliq.can_add_child?
      message = if @parent_cliq.child_cliqs.count >= Cliq::MAX_CHILD_CLIQS
                  "This cliq already has the maximum number of child cliqs (#{Cliq::MAX_CHILD_CLIQS})."
                else
                  "This cliq is already at the deepest level allowed."
                end

      respond_to do |format|
        format.html { redirect_to cliq_path(@parent_cliq), alert: message }
        format.turbo_stream do
          flash.now[:alert] = message
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "layouts/flash"),
            turbo_stream.replace("turbo-visit-placeholder", partial: "shared/turbo_visit", locals: { path: cliq_path(@parent_cliq) })
          ], status: :see_other
        end
      end
      return
    end

    @cliq = Cliq.new(parent_cliq: @parent_cliq)
    @cliq.posts.build
  end

  def search
    query = cliq_params[:name] # Use strong parameters for security
    if query.blank?
      render turbo_stream: turbo_stream.replace("cliq-search-results", partial: "cliqs/no_results")
    else
      @cliqs = Cliq.search(query)
      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def all
    # Exclude the top-level root Cliq that has parent_cliq_id: nil and no children
    @root_cliq = Cliq.find_by(parent_cliq_id: nil)

    @main_categories = Cliq.where(parent_cliq_id: @root_cliq.id).includes(child_cliqs: { child_cliqs: { child_cliqs: :child_cliqs } })
  end

  # GET /cliqs/1/edit
  def edit
  end

  # POST /cliqs or /cliqs.json
  def create
    @cliq = Cliq.new(cliq_params)
    @parent_cliq = @cliq.parent_cliq
    @cliq.posts.each { |post| post.user ||= current_user }
    @cliq.posts.build(user: current_user) if @cliq.posts.empty?
  
    if @cliq.save
      initial_post = @cliq.posts.order(:created_at).first
      redirect_path = if initial_post&.slug.present?
                        post_id_slug_post_path(post_id: initial_post.id, slug: initial_post.slug)
                      else
                        cliq_path(@cliq)
                      end

      flash[:notice] = "Cliq created."
      respond_to do |format|
        format.html        { redirect_to redirect_path }
        format.turbo_stream do
          flash.now[:notice] = "Cliq created."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "layouts/flash"),
            turbo_stream.replace("turbo-visit-placeholder", partial: "shared/turbo_visit", locals: { path: redirect_path })
          ]
        end
        format.json        { render :show, status: :created, location: @cliq }
      end
    else
      flash.now[:alert] = @cliq.errors.full_messages.to_sentence
      respond_to do |format|
        format.html         { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.json         { render json: @cliq.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cliqs/1 or /cliqs/1.json
  def update
    if @cliq.update(cliq_params)
      redirect_to cliqs_path, notice: "Cliq was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /cliqs/1 or /cliqs/1.json
  def destroy
    @cliq.destroy

    respond_to do |format|
      format.html { redirect_to cliqs_path, status: :see_other, notice: "Cliq was successfully destroyed." }
      format.turbo_stream
    end
  end

  private
  # infinite scrolling ---- 
  def posts_list_target
    params.fetch(:turbo_target, "posts")
  end

  def page
    params.fetch(:page, 1).to_i
  end

  def posts_scope
    if Current.user&.role_admin?
      Post.ordered
    else
      Post.ordered
    end
  end

  # end infinite scrolling ---- 


    # Use callbacks to share common setup or constraints between actions.
    def set_cliq
      identifier = params[:cliq_id].presence || params[:id]
      if identifier.present?
        @cliq = Cliq.friendly.find(identifier)
      else
        @cliq = Cliq.find_by(parent_cliq_id: nil)
      end
    end

    # Only allow a list of trusted parameters through.
    def cliq_params
      params.require(:cliq).permit(:name, :slug, :description, :parent_cliq_id,
                                   posts_attributes: [:title, :content])
    end
end
