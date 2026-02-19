class Api::CliqsController < Api::BaseController
  before_action :authenticate_api_user_optional!, only: [:show]
  before_action :extract_analytics_headers, only: [:show, :index]

  def index
    scope = Cliq.all
    
    if params[:sort] == 'popular' || params[:sort] == 'activity'
      scope = scope.order(posts_count: :desc)
    end
    
    if params[:limit].present?
       scope = scope.limit(params[:limit].to_i)
    end
    
    render json: { data: scope }
  end

  def show
    cliq = Cliq.find(params[:id])
    is_subscribed = current_user && cliq.subscriptions.exists?(user_id: current_user.id)
    
    render json: { 
      data: {
        id: cliq.id,
        name: cliq.name,
        description: cliq.description,
        parent_cliq_id: cliq.parent_cliq_id,
        rank: cliq.rank,
        slug: cliq.slug,
        posts_count: cliq.posts_count,
        canonical_id: cliq.canonical_id,
        lens: cliq.lens,
        is_alias: cliq.alias?,
        hierarchy: cliq.hierarchy_string,
        effective_cliq_id: cliq.effective_cliq.id,
        created_at: cliq.created_at,
        updated_at: cliq.updated_at,
        is_subscribed: is_subscribed,
        subscribed_through_parent: is_subscribed_through_parent(cliq),
        parent: cliq.parent_cliq ? cliq_json(cliq.parent_cliq) : nil,
        top_children: cliq.child_cliqs.top_children(10).map { |c| cliq_json(c) },
        all_children_count: cliq.child_cliqs.count,
        siblings: cliq.parent_cliq ? cliq.parent_cliq.child_cliqs.where.not(id: cliq.id).map { |c| cliq_json(c) } : []
      }
    }
  end

  def create
    cliq = Cliq.new(cliq_params)
    if cliq.save
      render json: { data: cliq }, status: :created
    else
      render json: { status: { code: 422, message: cliq.errors.full_messages.join(', ') } }, status: :unprocessable_entity
    end
  end

  def update
    cliq = Cliq.find(params[:id])
    if cliq.update(cliq_params)
      render json: { data: cliq }
    else
      render json: { status: { code: 422, message: cliq.errors.full_messages.join(', ') } }, status: :unprocessable_entity
    end
  end

  def destroy
    cliq = Cliq.find(params[:id])
    cliq.destroy
    head :no_content
  end

  def children
    # GET /api/cliqs/:id/children - Get all children with pagination
    parent_cliq = Cliq.find(params[:id])
    page = (params[:page] || 1).to_i
    per_page = 20
    
    children = parent_cliq.child_cliqs.top_children(999)
    total_count = parent_cliq.child_cliqs.count
    
    paginated_children = children
      .offset((page - 1) * per_page)
      .limit(per_page)
    
    render json: {
      data: paginated_children.map { |c| cliq_json(c) },
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  def search
    # GET /api/cliqs/search?q=query - Search cliqs by name and description
    query = params[:q].to_s.strip
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 10).to_i
    
    if query.blank?
      render json: {
        data: [],
        pagination: { page: page, per_page: per_page, total_count: 0, total_pages: 0 }
      }
      return
    end
    
    # Search in name and description, ranked by relevance then posts_count
    search_term = "%#{query}%"
    starts_with_term = "#{query}%"
    
    # Priority:
    # 0. Exact Name Match
    # 1. Name Starts With Query
    # 2. Name Contains Query
    # 3. Description Contains Query
    
    results = Cliq
      .where("LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", search_term, search_term)
      .order(Arel.sql("CASE 
        WHEN LOWER(name) = LOWER(#{Cliq.connection.quote(query)}) THEN 0
        WHEN LOWER(name) LIKE LOWER(#{Cliq.connection.quote(starts_with_term)}) THEN 1
        ELSE 2
      END"))
      .order(Arel.sql("COALESCE(posts_count, 0) DESC"))
      .order(:name)
    
    total_count = results.count
    paginated_results = results
      .offset((page - 1) * per_page)
      .limit(per_page)
    
    render json: {
      data: paginated_results.map { |c| cliq_json(c) },
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      },
      query: query
    }
  end

  def subscribe
    authenticate_api_user!
    cliq = Cliq.find(params[:id])
    
    # Find or create subscription to avoid duplicates
    subscription = current_user.subscriptions.find_or_create_by(cliq: cliq)
    
    render json: { 
      data: {
        id: cliq.id,
        name: cliq.name,
        is_subscribed: true
      }
    }, status: :created
  end

  def unsubscribe
    authenticate_api_user!
    cliq = Cliq.find(params[:id])
    subscription = current_user.subscriptions.find_by(cliq: cliq)
    
    if subscription&.destroy
      render json: { 
        data: {
          id: cliq.id,
          name: cliq.name,
          is_subscribed: false
        }
      }
    else
      render json: { status: { code: 404, message: "Subscription not found" } }, status: :not_found
    end
  end

  private

  def extract_analytics_headers
    # Extract headers forwarded by the frontend
    # We prefer the custom headers if present, otherwise fall back to the request's remote_ip/user_agent
    # (which might be the frontend server's IP if not configured as a trusted proxy)
    @visitor_ip = request.headers["X-Analytic-User-Ip"] || request.remote_ip
    @visitor_user_agent = request.headers["X-Analytic-User-Agent"] || request.user_agent

    if params[:action] == 'show' && params[:id].present?
      # Log the visit asynchronously-ish (at least in a way that doesn't block the logic too much)
      CliqVisit.log_visit(params[:id], @visitor_ip, @visitor_user_agent, current_user&.id)
    end
  end

  def cliq_params
    params.require(:cliq).permit(:name, :description, :parent_cliq_id, :rank, :slug, :canonical_id, :lens)
  end

  def is_subscribed_through_parent(cliq)
    return false unless current_user && cliq.parent_cliq
    
    # Check if user is subscribed to any parent cliq
    current_user.subscriptions.where(cliq_id: cliq.parent_cliq_id).exists?
  end

  def cliq_json(cliq)
    {
      id: cliq.id,
      name: cliq.name,
      description: cliq.description,
      parent_cliq_id: cliq.parent_cliq_id,
      rank: cliq.rank,
      slug: cliq.slug,
      posts_count: cliq.posts_count,
      canonical_id: cliq.canonical_id,
      lens: cliq.lens,
      is_alias: cliq.alias?,
      hierarchy: cliq.hierarchy_string,
      created_at: cliq.created_at,
      updated_at: cliq.updated_at
    }
  end
end
