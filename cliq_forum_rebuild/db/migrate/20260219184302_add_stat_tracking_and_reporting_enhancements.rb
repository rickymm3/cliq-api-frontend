class AddStatTrackingAndReportingEnhancements < ActiveRecord::Migration[8.0]
  def change
    # 1. Post Stat Tracking
    create_table :post_visits do |t|
      t.references :post, null: false, foreign_key: true
      t.string :visitor_hash, null: false
      t.date :visited_on, null: false, default: -> { 'CURRENT_DATE' }
      t.integer :user_id
      t.timestamps
    end
    # Ensure unique visit per day per hash
    add_index :post_visits, [:post_id, :visitor_hash, :visited_on], unique: true, name: 'index_unique_post_visit'

    create_table :post_daily_stats do |t|
      t.references :post, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :unique_visits_count, default: 0, null: false
      t.integer :raw_hits_count, default: 0, null: false
      t.timestamps
    end
    add_index :post_daily_stats, [:post_id, :date], unique: true

    # 2. Add Status and Hidden fields to Post
    add_column :posts, :status, :integer, default: 0 
    add_column :posts, :hidden_at, :datetime

    # 3. Add Status and Hidden fields to Reply
    add_column :replies, :status, :integer, default: 0
    add_column :replies, :hidden_at, :datetime
    add_column :replies, :heat_score, :float, default: 0.0
    add_column :replies, :reports_count, :integer, default: 0

    # 4. Polymorphic Reports
    # Remove old post_id association
    remove_column :reports, :post_id, :integer
    # Add polymorphic association
    add_reference :reports, :reportable, polymorphic: true, index: true

    # 5. User Preferences
    add_column :users, :view_contentious_content, :boolean, default: false
  end
end
