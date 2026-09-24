class User < ApplicationRecord
  has_many :reference_archives, dependent: :destroy

  validates :provider, :uid, :email, :name, presence: true
  validates :uid, uniqueness: { scope: :provider }
  validates :email, uniqueness: true
end
