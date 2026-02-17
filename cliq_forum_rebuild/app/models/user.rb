class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: self
  self.jwt_revocation_strategy = JwtDenylist
	has_many :posts
	has_many :replies, dependent: :destroy
	has_many :subscriptions, dependent: :destroy
	has_many :subscribed_cliqs, through: :subscriptions, source: :cliq
	has_many :notifications, dependent: :destroy
	has_many :sent_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :nullify
	has_many :active_followed_users, class_name: "FollowedUser", foreign_key: "follower_id", dependent: :destroy
	has_many :passive_followed_users, class_name: "FollowedUser", foreign_key: "followed_id", dependent: :destroy
	has_many :following, through: :active_followed_users, source: :followed
	has_many :followers, through: :passive_followed_users, source: :follower
  
  has_many :post_signals, dependent: :destroy
  has_many :signaled_posts, through: :post_signals, source: :post

	def follow(other_user)
		following << other_user
	end

	def unfollow(other_user)
		active_followed_users.find_by(followed_id: other_user.id)&.destroy
	end

	def following?(other_user)
		following.include?(other_user)
	end
	has_many :direct_message_conversations_as_user_a, class_name: "DirectMessageConversation", foreign_key: :user_a_id, dependent: :destroy, inverse_of: :user_a
	has_many :direct_message_conversations_as_user_b, class_name: "DirectMessageConversation", foreign_key: :user_b_id, dependent: :destroy, inverse_of: :user_b
	has_many :sent_direct_messages, class_name: "DirectMessage", foreign_key: :sender_id, dependent: :destroy, inverse_of: :sender
	has_many :received_direct_messages, class_name: "DirectMessage", foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
	has_many :post_interactions, dependent: :destroy
  
  has_many :moderator_subscriptions, dependent: :destroy
  has_many :moderated_cliqs, through: :moderator_subscriptions, source: :cliq
  has_many :moderation_votes, dependent: :destroy
end
