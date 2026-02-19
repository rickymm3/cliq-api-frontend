module Api
  class SearchController < ApplicationController
    def index
      query = params[:q].to_s.strip
      search_type = params[:type] || "all"  # all, cliqs, posts
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 10).to_i
      
      if query.blank?
        render json: {
          cliqs: [],
          posts: [],
          pagination: { page: page, per_page: per_page, total_count: 0, total_pages: 0 }
        }
        return
      end
      
      result = { query: query, page: page, per_page: per_page }
      search_term = "%#{query}%"
      
      # Search cliqs if requested
      if search_type == "all" || search_type == "cliqs"
        cliq_results = Cliq
          .where("LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", search_term, search_term)
          .order(Arel.sql("COALESCE(posts_count, 0) DESC"))
          .order(:name)
        
        cliq_total = cliq_results.count
        paginated_cliqs = cliq_results
          .offset((page - 1) * per_page)
          .limit(per_page)
        
        result[:cliqs] = {
          data: paginated_cliqs.map { |c| cliq_json(c) },
          pagination: {
            page: page,
            per_page: per_page,
            total_count: cliq_total,
            total_pages: (cliq_total.to_f / per_page).ceil
          }
        }
      end
      
      # Search posts if requested
      if search_type == "all" || search_type == "posts"
        # We need to join ActionText rich text table for content search
        post_results = Post
          .joins("LEFT JOIN action_text_rich_texts ON action_text_rich_texts.record_id = posts.id AND action_text_rich_texts.record_type = 'Post' AND action_text_rich_texts.name = 'content'")
          .where("LOWER(title) LIKE LOWER(?) OR LOWER(action_text_rich_texts.body) LIKE LOWER(?)", search_term, search_term)
          .where.not(visibility: 1)  # Filter out moderation posts
          .order(created_at: :desc)
          .includes(:user, :cliq)
          .distinct
        
        post_total = post_results.count 
        # Note: count on distinct with includes might be tricky in older rails, but 8.0 should handle it or we use .size
        
        paginated_posts = post_results
          .offset((page - 1) * per_page)
          .limit(per_page)
        
        result[:posts] = {
          data: paginated_posts.map { |p| post_json(p) },
          pagination: {
            page: page,
            per_page: per_page,
            total_count: post_total,
            total_pages: (post_total.to_f / per_page).ceil
          }
        }
      end
      
      render json: result
    end
    
    private
    
    def cliq_json(cliq)
      {
        id: cliq.id,
        name: cliq.name,
        description: cliq.description,
        hierarchy: cliq.hierarchy_string,
        parent_cliq_id: cliq.parent_cliq_id,
        rank: cliq.rank,
        slug: cliq.slug,
        posts_count: cliq.posts_count,
        created_at: cliq.created_at,
        updated_at: cliq.updated_at
      }
    end
    
    def post_json(post)
      parent_cliq = post.cliq.parent_cliq
      {
        id: post.id,
        slug: post.slug,
        title: post.title,
        content: post.content.to_s,
        post_type: post.post_type,
        visibility: post.visibility,
        user: {
          id: post.user.id,
          email: post.user.email
        },
        cliq: {
          id: post.cliq.id,
          name: post.cliq.name,
          hierarchy: post.cliq.hierarchy_string,
          parent_cliq_id: post.cliq.parent_cliq_id,
          parent_cliq: parent_cliq ? {
            id: parent_cliq.id,
            name: parent_cliq.name
          } : nil
        },
        created_at: post.created_at,
        updated_at: post.updated_at
      }
    end
  end
end
