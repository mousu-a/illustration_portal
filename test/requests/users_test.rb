require "test_helper"

class UsersTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:yamada)
  end

  test "DELETE /logout ログアウトする" do
    login(@user)

    delete logout_path

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "ログアウトしました"
  end

  test "DELETE /users/:id 退会する" do
    login(@user)

    assert_difference("User.count", -1) do
      delete user_path(@user)
    end

    assert_nil session[:user_id]
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "退会しました"
  end

  test "DELETE /users/:id 未ログインの場合は退会できない" do
    assert_no_difference("User.count") do
      delete user_path(@user)
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "ログインしてください"
  end

  test "GET /auth/google_oauth2/callback ログインする" do
    login(@user)

    assert_equal @user.id, session[:user_id]
    assert_redirected_to reference_archives_path
    follow_redirect!
    assert_includes response.body, "ログインしました"
  end

  test "GET /auth/google_oauth2/callback メールアドレスを取得できない場合は認証に失敗する" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash_for(uid: "New1234", provider: "google_oauth2", email: nil)

    get "/auth/google_oauth2/callback"

    assert_nil session[:user_id]
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "認証に失敗しました"
  end

  test "GET /auth/failure Google認証をキャンセルした場合、トップページへリダイレクトする" do
    get auth_failure_path

    assert_nil session[:user_id]
    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Googleログインがキャンセルされました"
  end
end
