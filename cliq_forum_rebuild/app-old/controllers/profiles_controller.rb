# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile
  before_action :ensure_owner!, only: :subscriptions

  def show
    build_overview

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def posts
    build_posts

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def articles
    build_articles

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def replies
    build_replies

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def subscriptions
    build_subscriptions
  end

  private

  def set_profile
    @profile = Profile.find_by!(username: params[:id])
    @user    = @profile.user
    @owner_viewing = current_user&.id == @user.id
  end

  def ensure_owner!
    return if @owner_viewing

    head :not_found
  end

  def build_overview
    @section = :overview
    @sort    = normalized_sort(default: 'recent_activity', allowed: %w[recent_activity created])

    base = Post.visible_in_feeds.where(user_id: @user.id)
               .left_joins(:replies)
               .group('posts.id')
               .includes(user: :profile, cliq: :parent_cliq)
               .reorder(nil)

    order_expr = if @sort == 'created'
                   'posts.created_at DESC'
                 else
                   'GREATEST(posts.created_at, COALESCE(MAX(replies.created_at), posts.created_at)) DESC'
                 end

    @pagy, @posts = pagy(base.order(Arel.sql(order_expr)))
    @next_page_url = @pagy.next ? profile_path(@profile, sort: @sort, page: @pagy.next) : nil
  end

  def build_posts
    @section = :posts
    @sort    = normalized_sort(default: 'created', allowed: %w[recent_activity created])

    base = @user.posts.visible_in_feeds.includes(user: :profile, cliq: :parent_cliq).order(created_at: :desc)
    # The posts list only needs created-desc ordering, but we keep the sort param for consistency.
    @pagy, @posts = pagy(base)
    @next_page_url = @pagy.next ? posts_profile_path(@profile, sort: @sort, page: @pagy.next) : nil
  end

  def build_articles
    @section = :articles
    @sort    = normalized_sort(default: 'created', allowed: %w[recent_activity created])

    base = @user.posts
                .where(post_type: Post.post_types[:article])
                .visible_in_feeds
                .includes(user: :profile, cliq: :parent_cliq)
                .order(created_at: :desc)

    @pagy, @posts = pagy(base)
    @next_page_url = @pagy.next ? articles_profile_path(@profile, sort: @sort, page: @pagy.next) : nil
  end

  def build_replies
    @section = :replies
    @pagy, @replies = pagy(@user.replies.includes(post: { user: :profile }).order(created_at: :desc))
    @next_page_url = @pagy.next ? replies_profile_path(@profile, page: @pagy.next) : nil
  end

  def build_subscriptions
    @section = :subscriptions

    return unless @owner_viewing && defined?(Subscription)

    @subscriptions     = @user.subscriptions.includes(cliq: :parent_cliq)
    @subscribed_groups = @user.subscribed_cliqs.includes(:parent_cliq).group_by { |c| c.ancestors.any? ? c.ancestors.first : c }
  end

  def normalized_sort(default:, allowed:)
    value = params[:sort].presence
    allowed.include?(value) ? value : default
  end
end
