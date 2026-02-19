class CreateCliqVisitsAndDailyStats < ActiveRecord::Migration[8.0]
  def change
    # 1. Raw visits table - High churn, deduplicates unique visitors per day
    create_table :cliq_visits do |t|
      t.references :cliq, null: false, foreign_key: true
      t.string :visitor_hash, null: false # SHA256(IP + UserAgent + Salt)
      t.date :visited_on, null: false, default: -> { 'CURRENT_DATE' }
      t.integer :user_id, null: true # Optional: track logged in user ID if available

      t.timestamps
    end

    # unique index prevents duplicate visits from same visitor per day
    add_index :cliq_visits, [:cliq_id, :visitor_hash, :visited_on], unique: true, name: 'index_unique_cliq_visit'

    # 2. Aggregated stats table - Long term storage
    create_table :cliq_daily_stats do |t|
      t.references :cliq, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :unique_visits_count, default: 0, null: false
      t.integer :raw_hits_count, default: 0, null: false

      t.timestamps
    end

    add_index :cliq_daily_stats, [:cliq_id, :date], unique: true
  end
end
