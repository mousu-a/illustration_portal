require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "terms は利用規約を表示する" do
    get terms_path

    assert_response :success
    assert_select "h1", "利用規約"
    assert_match "第1条 本規約の適用", response.body
    assert_match "第2条 サービス内容", response.body
    assert_match "第3条 保存するURLおよび外部コンテンツ", response.body
    assert_match "本サービスのサーバーには保存しません", response.body
    assert_match "第15条 通知および連絡先", response.body
    assert_select "a[href=?]", "mailto:natubate870@gmail.com"
    assert_match "第16条 準拠法・裁判管轄", response.body
    assert_select "a[href=?]", privacy_path
  end

  test "footer は利用規約とプライバシーポリシーへのリンクを表示する" do
    get terms_path

    assert_select "footer a[href=?]", terms_path, "利用規約"
    assert_select "footer a[href=?]", privacy_path, "プライバシーポリシー"
  end

  test "footer はログイン中のみ退会ボタンを表示する" do
    login(users(:yamada))

    get terms_path

    assert_select "footer form[action=?] button", user_path(users(:yamada)), "退会する"
  end

  test "footer は未ログインの場合は退会ボタンを表示しない" do
    get terms_path

    assert_select "footer form button", false
  end

  test "アカウントメニューには退会ボタンを表示しない" do
    login(users(:yamada))

    get reference_archives_path

    assert_select ".account-menu__panel form[action=?]", user_path(users(:yamada)), false
  end

  test "privacy はプライバシーポリシーを表示する" do
    get privacy_path

    assert_response :success
    assert_match "プライバシーポリシー", response.body
    assert_match "第1条（個人情報）", response.body
    assert_match "Googleアカウントによるログイン", response.body
    assert_match "第三者提供記録", response.body
    assert_match "第8条（お問い合わせ窓口）", response.body
    assert_match "natubate870@gmail.com", response.body
    assert_match "最終改定日：2026年10月20日", response.body
    assert_no_match ">以上<", response.body
  end
end
