require "test_helper"

class WelcomeTest < ActionDispatch::IntegrationTest
  test "未ログインの場合はウェルカムページを表示する" do
    get root_path

    assert_response :success
    assert_select "button", "Googleでログイン"
  end

  test "ログイン中の場合はブックマーク一覧へリダイレクトする" do
    login(users(:tanaka))

    get root_path

    assert_redirected_to reference_archives_path
  end
end
