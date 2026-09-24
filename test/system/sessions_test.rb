require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:yamada)
  end

  test "名前が空でもログイン(または登録)できる" do
    login(@user, name: "")

    assert_text "ログインしました"
  end

  test "ログアウトする" do
    login(@user)

    click_on "ログアウト"

    assert_text "ログアウトしました"
  end
end
