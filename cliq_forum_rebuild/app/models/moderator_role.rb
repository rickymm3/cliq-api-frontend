class ModeratorRole < ApplicationRecord
	belongs_to :cliq
	belongs_to :user
end
