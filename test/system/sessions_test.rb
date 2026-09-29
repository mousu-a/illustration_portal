require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    @user = users(:yamada)
  end

  test "名前が空でもログイン(または登録)できる" do
    login(@user, name: "")

    assert_text "ログインしました"
  end

  test "フラッシュメッセージは数秒後に自動で消える" do
    login(@user)

    assert_text "ログインしました"
    assert_no_text "ログインしました", wait: 6
  end

  test "ログアウトする" do
    login(@user)

    find(".account-menu__trigger").click
    click_on "ログアウト"

    assert_text "ログアウトしました"
  end

  test "ユーザーメニューはメニューの外側をクリックすると閉じる" do
    login(@user)

    find(".account-menu__trigger").click
    assert_button "ログアウト"

    find(".sidebar__title").click

    assert_no_button "ログアウト"
  end
end
