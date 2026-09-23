require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "welcome はウェルカム画面を表示する" do
    get welcome_path

    assert_response :success
  end

  test "privacy はプライバシーポリシーを表示する" do
    get privacy_path

    assert_response :success
    assert_match "プライバシーポリシー", response.body
  end
end
