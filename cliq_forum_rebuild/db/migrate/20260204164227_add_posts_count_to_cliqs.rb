class AddPostsCountToCliqs < ActiveRecord::Migration[8.0]
  def change
    add_column :cliqs, :posts_count, :integer, default: 0
    
    # Populate existing data with count of posts in this cliq
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE cliqs 
          SET posts_count = (SELECT COUNT(*) FROM posts WHERE posts.cliq_id = cliqs.id)
        SQL
      end
    end
  end
end
