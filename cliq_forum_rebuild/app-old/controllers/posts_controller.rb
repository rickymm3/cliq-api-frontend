class PostsController < ApplicationController
  # before_action :set_post, only: %i[ show edit update destroy ]
  before_action :authenticate_user!, only: [:new, :create]
  before_action :load_post_for_show, only: :show

  # GET /posts or /posts.json
  # def index
  #   if params[:cliq_id]
  #     @cliq = Cliq.find(params[:cliq_id])
  #     cliq_ids = @cliq.self_and_descendant_ids
  #     @posts = Post.where(cliq_id: cliq_ids).order(created_at: :desc)
  #   else
  #     @posts = Post.all.order(created_at: :desc) # or whatever default behavior you want
  #   end
  #   # Render or redirect as per your application's needs
  # end

  def index
    # if params[:cliq_id]
    #   @cliq = Cliq.find(params[:cliq_id])
    #   cliq_ids = @cliq.self_and_descendant_ids
    #   @posts = Post.where(cliq_id: cliq_ids).order(created_at: :desc)
    # else
    #   @cliq = Cliq.find_by(parent_cliq_id: nil)
    #   @posts = Post.all.order(created_at: :desc) 
    # end
  
    # # Assuming you're using some form of pagination like Kaminari or Pagy
    # @posts = @posts.page(params[:page]).per(10) # Adjust per_page as needed
  
    # respond_to do |format|
    #   format.html # Renders the index.html.erb
    #   format.turbo_stream do
    #     render partial: 'posts/shared/posts', locals: { posts: @posts }, formats: [:html]
    #   end
    # end
  end


  # GET /posts/1 or /posts/1.json
  def show
    @replies = @post.replies.order(created_at: :desc)
    @post.register_click!
    @post.register_view!
  end

  # GET /posts/new
  def new
    @cliq = Cliq.find_by(id: params[:cliq_id]) if params[:cliq_id].present?
    @post = Post.new(post_type: (params[:post_type].presence || :discussion))
  
    # Important: always render the full template so the response contains the frame
    render :new
  end

  # GET /posts/1/edit
  def edit
    authorize @post = Post.find(params[:id])
    @cliq = @post.cliq
  end

  def soft_delete
    @post = Post.find(params[:id])
    # If you use Pundit, uncomment:
    # authorize @post
  
    @post.update!(deleted: true)
  
    target = post_id_slug_post_path(post_id: @post.id, slug: @post.slug)
    respond_to do |format|
      format.html        { redirect_to target, notice: I18n.t("posts.deleted_notice") }
      format.turbo_stream { redirect_to target, status: :see_other }
    end
  end

  # POST /posts or /posts.json
  def create
    permitted = post_params
    attachments = extract_attachment_params!(permitted)
    @post = Post.new(permitted.except(:new_cliq_name, :new_cliq_parent_id))
    @post.user = current_user
    @post.post_type ||= :discussion
    attach_files(@post, attachments)

    new_name = permitted[:new_cliq_name].to_s.strip
    parent   = permitted[:new_cliq_parent_id].present? ? Cliq.find_by(id: permitted[:new_cliq_parent_id]) : nil
  
    if new_name.present?
      # Duplicate pre-check
      if Cliq.exists?(name: new_name, parent_cliq: parent)
        @parent_cliq = parent
        msg = "Cliq “#{new_name}” already exists under #{parent ? "“#{parent.name}”" : "the root"}"
        @post.errors.add(:base, msg)
        flash.now[:alert] = msg
  
        respond_to do |format|
          format.html         { render 'cliqs/new', status: :unprocessable_entity }
          format.turbo_stream { render 'cliqs/new', status: :unprocessable_entity }
        end
        return
      end
  
      ActiveRecord::Base.transaction do
        cliq = Cliq.new(name: new_name, parent_cliq: parent)
        unless cliq.save
          @parent_cliq = parent
          msg = cliq.errors.full_messages.to_sentence
          @post.errors.add(:base, msg)
          flash.now[:alert] = msg
          raise ActiveRecord::RecordInvalid, @post
        end

        unless ensure_moderation_candidate_allowed!(@post, cliq)
          flash.now[:alert] ||= @post.errors.full_messages.to_sentence
          raise ActiveRecord::RecordInvalid, @post
        end

        @post.cliq = cliq
        @post.save!
      end
    else
      if @post.cliq_id.blank? || !Cliq.exists?(@post.cliq_id)
        @cliq = Cliq.find_by(id: permitted[:cliq_id])
        msg = "Please choose a cliq or create a new one."
        @post.errors.add(:cliq, msg)
        flash.now[:alert] = msg

        respond_to do |format|
          format.html         { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
        return
      end

      @cliq = Cliq.find(@post.cliq_id)
      unless ensure_moderation_candidate_allowed!(@post, @cliq)
        flash.now[:alert] = @post.errors.full_messages.to_sentence
        respond_to do |format|
          format.html         { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
        return
      end

      ActiveRecord::Base.transaction { @post.save! }
    end
  
    target = post_id_slug_post_path(post_id: @post.id, slug: @post.slug)
    respond_to do |format|
      format.html         { redirect_to target, notice: "Post created." }
      format.turbo_stream { redirect_to target, status: :see_other }
      format.json         { render :show, status: :created, location: target }
    end
  rescue ActiveRecord::RecordInvalid
    if new_name.present?
      @parent_cliq = parent
      render 'cliqs/new', status: :unprocessable_entity
    else
      @cliq = @post.cliq || Cliq.find_by(id: permitted[:cliq_id])
      render :new, status: :unprocessable_entity
    end
  end


  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    @post = Post.friendly.find(params[:id])
    permitted = post_params
    attachments = extract_attachment_params!(permitted)

    @post.assign_attributes(permitted)
    attach_files(@post, attachments)

    unless ensure_moderation_candidate_allowed!(@post, @post.cliq)
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html         { render :edit, status: :unprocessable_entity }
        format.json         { render json: @post.errors, status: :unprocessable_entity }
      end
      return
    end

    if @post.save
      @post.register_edit!
      # Ensure replies are available for the show template
      @replies = @post.replies.order(created_at: :desc)
  
      respond_to do |format|
        # Turbo edit -> replace main_content with the full show view (now with replies)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('main_content', template: 'posts/show')
        end
  
        # Non-Turbo / HTML edit -> go to the canonical post URL
        format.html do
          target = post_id_slug_post_path(post_id: @post.id, slug: @post.slug)
          redirect_to target, notice: "Post updated."
        end
  
        # Optional JSON
        format.json { render :show, status: :ok, location: @post }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html         { render :edit, status: :unprocessable_entity }
        format.json         { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_path, status: :see_other, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def popular
    @popular_scope = params[:scope] == "subscribed" ? :subscribed : :global

    base = Post.hot.visible_in_feeds
               .includes(:user, :cliq)
               .order(heat_score: :desc, updated_at: :desc)

    if @popular_scope == :subscribed
      if current_user
        effective_ids = current_user.effective_enabled_subscription_ids
        if effective_ids.present?
          subscribed_scope_ids = []
          Cliq.where(id: effective_ids).includes(:child_cliqs).find_each do |cliq|
            subscribed_scope_ids.concat(cliq.self_and_descendant_ids)
          end
          subscribed_scope_ids.uniq!
          base = subscribed_scope_ids.present? ? base.where(cliq_id: subscribed_scope_ids) : base.none
        else
          base = base.none
        end
      else
        @popular_scope = :global
      end
    end

    @pagy, @posts = pagy(base)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render partial: "posts/post", collection: @posts, as: :post, formats: [:html]
      end
    end
  end

  private
    def load_post_for_show
      @post = Post.friendly.find(params[:post_id])
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.friendly.find(params[:id]) 
    end

    # Only allow a list of trusted parameters through.
    def extract_attachment_params!(attributes)
      attachments = {
        lead_image: attributes.delete(:lead_image),
        article_header_image: attributes.delete(:article_header_image),
        article_inline_image_one: attributes.delete(:article_inline_image_one),
        article_inline_image_two: attributes.delete(:article_inline_image_two)
      }

      attachments.transform_values! do |value|
        value.respond_to?(:presence) ? value.presence : value
      end

      attachments
    end

    def attach_files(post, attachments)
      attachments.each do |key, file|
        next if file.blank?
        attachment = post.public_send(key)
        next unless attachment.respond_to?(:attach)
        attachment.attach(file)
      end
    end

    def ensure_moderation_candidate_allowed!(post, cliq)
      return true unless post.visibility_moderation?

      unless current_user.established_for_moderation?
        post.errors.add(:base, "Only established members can create moderator candidacy posts.")
      end

      unless post.persisted?
        limiter = Moderation::RateLimiter.new(current_user)
        unless limiter.can_create_moderation_post?(cliq)
          post.errors.add(:base, "You recently submitted a moderator candidacy for this cliq.")
        end
      end

      post.errors.empty?
    end

    def post_params
      params.require(:post).permit(
        :title, :content, :cliq_id,
        :new_cliq_name, :new_cliq_parent_id,
        :lead_image,
        :article_header_image,
        :article_inline_image_one,
        :article_inline_image_two,
        :post_type,
        :visibility  # moderation candidacy posts
      )
    end
    
end
