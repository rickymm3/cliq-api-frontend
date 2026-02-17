class Subscription < ApplicationRecord
	belongs_to :user
	belongs_to :cliq
	
	validates :user_id, uniqueness: { scope: :cliq_id, message: "can only subscribe to a cliq once" }
end
