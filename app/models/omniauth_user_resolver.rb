class OmniAuthUserResolver
  def self.find_or_create_user(auth)
    new(auth).find_or_create_user
  end

  def initialize(auth)
    @auth = auth
  end

  def find_or_create_user
    User.find_or_create_by(provider: @auth.provider, uid: @auth.uid) do |user|
      user.assign_attributes(profile_attributes)
    end
  end

  private

  def profile_attributes
    {
      email: @auth.info.email,
      name: @auth.info.name.presence || I18n.t("users.guest"),
      avatar_url: @auth.info.image
    }
  end
end
