class HeatRecalculationJob
  include Sidekiq::Job

  def perform
    Post.find_each { |post| post.calculate_heat }
  end
end
