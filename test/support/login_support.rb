module LoginSupport
  module System
    def login(user, name: user.name)
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash_for(
        uid: user.uid, provider: user.provider, email: user.email, name:, image: user.avatar_url
      )
      visit root_path
      click_on "Googleでログイン"

      assert_current_path reference_archives_path
      assert_text "ログインしました"
    end
  end

  module Request
    def login(user)
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash_for(
        uid: user.uid, provider: user.provider, email: user.email, name: user.name, image: user.avatar_url
      )
      get "/auth/#{user.provider}/callback"
    end
  end
end
