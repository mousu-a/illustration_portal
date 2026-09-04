class ReferenceArchive < ApplicationRecord
  belongs_to :user
  has_many :taggings
  has_many :tags, through: :taggings
end
