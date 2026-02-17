class SearchController < ApplicationController
  include ApiClient

  def index
    @query = params[:q].to_s.strip
    @search_type = params[:type] || "all"  # all, cliqs, posts
    @page = (params[:page] || 1).to_i
    
    @cliq_results = []
    @post_results = []
    @cliq_pagination = {}
    @post_pagination = {}
    
    if @query.present?
      search_response = api_get("search", { q: @query, type: @search_type, page: @page, per_page: 20 })
      
      if (@search_type == "all" || @search_type == "cliqs") && search_response["cliqs"]
        @cliq_results = search_response["cliqs"]["data"] || []
        @cliq_pagination = search_response["cliqs"]["pagination"] || {}
      end
      
      if (@search_type == "all" || @search_type == "posts") && search_response["posts"]
        @post_results = search_response["posts"]["data"] || []
        @post_pagination = search_response["posts"]["pagination"] || {}
      end
    end
  end
end
