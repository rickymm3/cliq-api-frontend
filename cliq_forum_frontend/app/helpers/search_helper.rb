module SearchHelper
  def paginate_search_results(pagination, query, type)
    render partial: "pagination", locals: {
      pagination: pagination,
      query: query,
      type: type
    }
  end
end
