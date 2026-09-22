class User < ApplicationRecord
  has_many :reference_archives

  # TODO: Google OAuth実装Issueで session[:user_id] を使った本実装に差し替えたら削除する
  def self.find_or_create_dev_user
    find_or_create_by!(provider: "dev", uid: "dev-user") do |user|
      user.email = "dev@example.com"
      user.name = "Dev User"
    end
  end
end
