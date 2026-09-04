class Tag < ApplicationRecord
  has_many :taggings
  has_many :reference_archives, through: :taggings
end
