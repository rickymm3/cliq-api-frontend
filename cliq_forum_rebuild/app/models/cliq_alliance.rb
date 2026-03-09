class CliqAlliance < ApplicationRecord
  belongs_to :source_cliq, class_name: 'Cliq'
  belongs_to :target_cliq, class_name: 'Cliq'
end
