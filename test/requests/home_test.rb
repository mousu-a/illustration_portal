require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
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
