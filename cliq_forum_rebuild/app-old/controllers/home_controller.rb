class HomeController < ApplicationController
  def index
    base = Post.visible_in_feeds.ordered.includes(:user, :cliq)
    @pagy, @posts = pagy(base)
    set_page_cliq
  end
end
