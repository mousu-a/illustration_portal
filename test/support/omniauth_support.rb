module OmniAuthSupport
  def auth_hash_for(uid:, provider:, email: "test_user@example.com", name: "test_user", image: "https://example.com/test_user.jpg")
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: name, image: image }
    )
  end
end
