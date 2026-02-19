# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_19_142655) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cliq_alias_proposals", force: :cascade do |t|
    t.bigint "cliq_id", null: false
    t.bigint "parent_cliq_id", null: false
    t.string "alias_name", null: false
    t.string "lens"
    t.bigint "proposer_id", null: false
    t.integer "status", default: 0
    t.integer "votes_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliq_id"], name: "index_cliq_alias_proposals_on_cliq_id"
    t.index ["parent_cliq_id"], name: "index_cliq_alias_proposals_on_parent_cliq_id"
    t.index ["proposer_id"], name: "index_cliq_alias_proposals_on_proposer_id"
  end

  create_table "cliq_daily_stats", force: :cascade do |t|
    t.bigint "cliq_id", null: false
    t.date "date", null: false
    t.integer "unique_visits_count", default: 0, null: false
    t.integer "raw_hits_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliq_id", "date"], name: "index_cliq_daily_stats_on_cliq_id_and_date", unique: true
    t.index ["cliq_id"], name: "index_cliq_daily_stats_on_cliq_id"
  end

  create_table "cliq_merge_proposal_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cliq_merge_proposal_id", null: false
    t.boolean "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliq_merge_proposal_id"], name: "index_cliq_merge_proposal_votes_on_cliq_merge_proposal_id"
    t.index ["user_id", "cliq_merge_proposal_id"], name: "idx_on_user_id_cliq_merge_proposal_id_a7db66b013", unique: true
    t.index ["user_id"], name: "index_cliq_merge_proposal_votes_on_user_id"
  end

  create_table "cliq_merge_proposals", force: :cascade do |t|
    t.bigint "source_cliq_id", null: false
    t.bigint "target_cliq_id", null: false
    t.bigint "proposer_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "phase_1_expires_at"
    t.datetime "phase_2_expires_at"
    t.integer "yes_votes", default: 0, null: false
    t.integer "no_votes", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proposer_id"], name: "index_cliq_merge_proposals_on_proposer_id"
    t.index ["source_cliq_id"], name: "index_cliq_merge_proposals_on_source_cliq_id"
    t.index ["target_cliq_id"], name: "index_cliq_merge_proposals_on_target_cliq_id"
  end

  create_table "cliq_visits", force: :cascade do |t|
    t.bigint "cliq_id", null: false
    t.string "visitor_hash", null: false
    t.date "visited_on", default: -> { "CURRENT_DATE" }, null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliq_id", "visitor_hash", "visited_on"], name: "index_unique_cliq_visit", unique: true
    t.index ["cliq_id"], name: "index_cliq_visits_on_cliq_id"
  end

  create_table "cliqs", force: :cascade do |t|
    t.string "name"
    t.integer "parent_cliq_id"
    t.integer "rank"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "posts_count", default: 0
    t.bigint "canonical_id"
    t.string "lens"
    t.index ["canonical_id"], name: "index_cliqs_on_canonical_id"
  end

  create_table "direct_message_conversations", force: :cascade do |t|
    t.integer "user_a_id"
    t.integer "user_b_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "direct_messages", force: :cascade do |t|
    t.text "body"
    t.integer "sender_id"
    t.integer "recipient_id"
    t.integer "conversation_id"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "followed_users", force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_followed_users_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_followed_users_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_followed_users_on_follower_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "moderation_votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.integer "vote_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_moderation_votes_on_post_id"
    t.index ["user_id", "post_id"], name: "index_moderation_votes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_moderation_votes_on_user_id"
  end

  create_table "moderator_roles", force: :cascade do |t|
    t.integer "user_id"
    t.integer "cliq_id"
    t.integer "role_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "moderator_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cliq_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cliq_id"], name: "index_moderator_subscriptions_on_cliq_id"
    t.index ["user_id", "cliq_id"], name: "index_moderator_subscriptions_on_user_id_and_cliq_id", unique: true
    t.index ["user_id"], name: "index_moderator_subscriptions_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "recipient_id"
    t.integer "actor_id"
    t.string "notifiable_type"
    t.integer "notifiable_id"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "post_interactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.integer "preference", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_interactions_on_post_id"
    t.index ["user_id", "post_id"], name: "index_post_interactions_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_post_interactions_on_user_id"
  end

  create_table "post_links", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.string "lens_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cliq_id", null: false
    t.index ["cliq_id"], name: "index_post_links_on_cliq_id"
    t.index ["post_id", "lens_id"], name: "index_post_links_on_post_id_and_lens_id", unique: true
    t.index ["post_id"], name: "index_post_links_on_post_id"
  end

  create_table "post_signals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_signals_on_post_id"
    t.index ["user_id", "post_id"], name: "index_post_signals_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_post_signals_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "user_id"
    t.integer "cliq_id"
    t.integer "post_type"
    t.integer "visibility", default: 0
    t.datetime "hot_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.float "heat_score", default: 0.0
    t.integer "views_count", default: 0
    t.integer "replies_count", default: 0
    t.integer "reports_count", default: 0
    t.bigint "cliq_merge_proposal_id"
    t.integer "kind", default: 0
    t.index ["cliq_merge_proposal_id"], name: "index_posts_on_cliq_merge_proposal_id"
    t.index ["heat_score"], name: "index_posts_on_heat_score"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "replies", force: :cascade do |t|
    t.text "content"
    t.integer "user_id"
    t.integer "post_id"
    t.integer "parent_reply_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "reporter_id"
    t.integer "cliq_id"
    t.integer "post_id"
    t.string "reason"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "cliq_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "cliq_id"], name: "index_subscriptions_on_user_id_and_cliq_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "followers_count", default: 0, null: false
    t.integer "following_count", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cliq_alias_proposals", "cliqs"
  add_foreign_key "cliq_alias_proposals", "cliqs", column: "parent_cliq_id"
  add_foreign_key "cliq_alias_proposals", "users", column: "proposer_id"
  add_foreign_key "cliq_daily_stats", "cliqs"
  add_foreign_key "cliq_merge_proposal_votes", "cliq_merge_proposals"
  add_foreign_key "cliq_merge_proposal_votes", "users"
  add_foreign_key "cliq_merge_proposals", "cliqs", column: "source_cliq_id"
  add_foreign_key "cliq_merge_proposals", "cliqs", column: "target_cliq_id"
  add_foreign_key "cliq_merge_proposals", "users", column: "proposer_id"
  add_foreign_key "cliq_visits", "cliqs"
  add_foreign_key "cliqs", "cliqs", column: "canonical_id"
  add_foreign_key "moderation_votes", "posts"
  add_foreign_key "moderation_votes", "users"
  add_foreign_key "moderator_subscriptions", "cliqs"
  add_foreign_key "moderator_subscriptions", "users"
  add_foreign_key "post_interactions", "posts"
  add_foreign_key "post_interactions", "users"
  add_foreign_key "post_links", "cliqs"
  add_foreign_key "post_links", "posts"
  add_foreign_key "post_signals", "posts"
  add_foreign_key "post_signals", "users"
  add_foreign_key "posts", "cliq_merge_proposals"
end
