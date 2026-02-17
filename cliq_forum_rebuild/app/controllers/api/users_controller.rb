class Api::UsersController < Api::BaseController
  include PostSerializable
  before_action :authenticate_api_user_optional!, only: [:show, :index, :followers, :following]
  
  def index
    users = User.all
    render json: { data: users }
  end

  def show
    user = User.find(params[:id])
    render json: user_profile_json(user)
  end

  def create
    user = User.new(user_params)
    if user.save
      token = generate_jwt_token(user)
      
      render json: { 
        status: { code: 200, message: 'User created successfully.' },
        data: user.as_json.merge(authentication_token: token)
      }, status: :created
    else
      render json: { 
        status: { code: 422, message: user.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  def sign_in
    user = User.find_by(email: params[:user][:email])
    
    if user && user.valid_password?(params[:user][:password])
      token = generate_jwt_token(user)
      
      render json: { 
        status: { code: 200, message: 'Logged in successfully.' },
        data: user.as_json.merge(authentication_token: token)
      }, status: :ok
    else
      render json: { 
        status: { code: 401, message: 'Invalid email or password.' }
      }, status: :unauthorized
    end
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: { data: user }
    else
      render json: { 
        status: { code: 422, message: user.errors.full_messages.join(', ') }
      }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    head :no_content
  end

  def followers
    user = User.find(params[:id])
    followers = user.followers
    render json: { data: followers.map { |u| serialize_user_basic(u, current_user) } }
  end

  def following
    user = User.find(params[:id])
    following = user.following.left_joins(:posts).group('users.id').order('COUNT(posts.id) DESC')
    render json: { data: following.map { |u| serialize_user_basic(u, current_user) } }
  end

  def subscriptions
    authenticate_api_user!
    user = User.find(params[:id])
    
    # Only allow users to see their own subscriptions
    if current_user.id != user.id
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end
    
    sorted_subscriptions = user.subscriptions.includes(:cliq).sort_by { |s| -s.cliq.posts_count }
    
    render json: {
      subscriptions: sorted_subscriptions.map { |s| 
        { 
          cliq_id: s.cliq.id,
          name: s.cliq.name,
          description: s.cliq.description,
          parent_cliq_id: s.cliq.parent_cliq_id,
          posts_count: s.cliq.posts_count
        }
      }
    }
  end

  def subscribed_feed
    authenticate_api_user!
    page = (params[:page] || 1).to_i
    per_page = params[:per_page] || 20
    
    # Get all cliq IDs the user is subscribed to
    subscribed_cliq_ids = current_user.subscriptions.pluck(:cliq_id)
    
    # Also include children of subscribed parent cliqs
    subscribed_cliqs = Cliq.where(id: subscribed_cliq_ids)
    all_cliq_ids = subscribed_cliq_ids.dup
    
    subscribed_cliqs.each do |cliq|
      # If user subscribed to parent, include all children
      child_ids = cliq.child_cliqs.pluck(:id)
      all_cliq_ids.concat(child_ids)
    end
    
    all_cliq_ids.uniq!
    
    # Get posts from these cliqs, ordered by creation date
    posts = Post.where(cliq_id: all_cliq_ids).order(created_at: :desc)
    
    total_count = posts.count
    total_pages = (total_count.to_f / per_page).ceil
    
    paginated_posts = posts
      .offset((page - 1) * per_page)
      .limit(per_page)
      .includes(:cliq, :user)
    
    render json: {
      data: paginated_posts.map { |p| serialize_post(p, current_user) },
      pagination: {
        current_page: page,
        next_page: page < total_pages ? page + 1 : nil,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end

  def following_feed
    authenticate_api_user!
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i

    following_ids = current_user.following.pluck(:id)
    
    # 1. Direct Posts from followed users
    recent_posts = Post.where(user_id: following_ids)
                       .where('created_at > ?', 30.days.ago)
                       .includes(:cliq, :user)
                       .order(created_at: :desc)
                       .limit(200)
    
    # 2. Signals from followed users (Active only)
    recent_signals = PostSignal.where(user_id: following_ids)
                               .active
                               .includes(:post => [:cliq, :user], :user => [])
                               .order(created_at: :desc)
                               .limit(100)
    
    # Merge
    feed_items = []
    
    recent_posts.each do |post|
      feed_items << {
        type: 'post',
        timestamp: post.created_at,
        object: post
      }
    end
    
    recent_signals.each do |signal|
      next unless signal.post
      # Check if we already have this post from the original author (if we follow them too)
      # But technically a Signal is a "Retweet", so showing it again with context is fine/desired.
      feed_items << {
        type: 'signal',
        timestamp: signal.created_at,
        object: signal.post,
        signaler: signal.user
      }
    end
    
    # Sort by timestamp (descending)
    sorted_items = feed_items.sort_by { |item| item[:timestamp] }.reverse
    
    # Paginate in memory
    total_count = sorted_items.count
    total_pages = (total_count.to_f / per_page).ceil
    start_index = (page - 1) * per_page
    paginated_items = sorted_items[start_index, per_page] || []
    
    data = paginated_items.map do |item|
      serialized = serialize_post(item[:object], current_user)
      if item[:type] == 'signal'
        serialized[:feed_context] = {
           type: 'signal',
           signaler: { id: item[:signaler].id, email: item[:signaler].email },
           timestamp: item[:timestamp]
        }
      end
      serialized
    end
    
    render json: {
      data: data,
      pagination: {
        current_page: page,
        next_page: page < total_pages ? page + 1 : nil,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def user_profile_json(user)
    data = {
      id: user.id,
      email: user.email,
      posts_count: user.posts.count,
      followers_count: user.followers_count,
      following_count: user.following_count,
      created_at: user.created_at,
      updated_at: user.updated_at,
      posts: user.posts.includes(:cliq, :user).order(created_at: :desc).limit(10).map { |p| serialize_post(p, current_user) },
      recent_signals: user.signaled_posts.includes(:cliq, :user).order('post_signals.created_at DESC').limit(5).map { |p| serialize_post(p, current_user).merge(signaled_at: p.updated_at) },
      subscriptions: user.subscriptions.includes(:cliq).sort_by { |s| -s.cliq.posts_count }.map { |s| cliq_json(s.cliq) }
    }
    
    if current_user
      data[:is_following] = current_user.following?(user)
      data[:is_self] = (current_user.id == user.id)
    end

    data
  end

  def cliq_json(cliq)
    {
      id: cliq.id,
      name: cliq.name,
      description: cliq.description,
      parent_cliq_id: cliq.parent_cliq_id,
      posts_count: cliq.posts_count
    }
  end

  def generate_jwt_token(user)
    payload = { 
      sub: user.id, 
      iat: Time.current.to_i,
      exp: (Time.current + 7.days).to_i
    }
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  def serialize_user_basic(user, viewer)
    {
      id: user.id,
      email: user.email,
      posts_count: user.posts.count,
      is_following: viewer ? viewer.following?(user) : false,
      is_self: viewer ? (viewer.id == user.id) : false
    }
  end
end
