module LoginSupport
  module System
    def login(user, name: user.name)
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash_for(
        uid: user.uid, provider: user.provider, email: user.email, name:, image: user.avatar_url
      )
      # ログイン済みのcookieが残る（セッションが維持されたまま始まってしまう）ことがあるため、念の為cookieを消す
      visit rails_health_check_path
      page.driver.browser.manage.delete_all_cookies

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
