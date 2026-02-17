class Reply < ApplicationRecord
	belongs_to :post, counter_cache: true, touch: true
	belongs_to :user
	belongs_to :parent_reply, class_name: "Reply", optional: true
	has_many :child_replies, class_name: "Reply", foreign_key: :parent_reply_id, dependent: :nullify
	has_rich_text :content

	after_create :recalculate_post_heat

	private

	def recalculate_post_heat
		post.calculate_heat
	end
end
