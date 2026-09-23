require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "welcome はウェルカムページを表示する" do
    get welcome_path

    assert_response :success
  end

  test "terms は利用規約ページを表示する" do
    get terms_path

    assert_response :success
    assert_select "h1", "利用規約"
  end
end
