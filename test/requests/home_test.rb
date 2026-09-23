require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "#welcome はルートでトップページを表示する" do
    get root_path

    assert_response :success
  end

  test "#welcome は/welcomeでもトップページを表示する" do
    get welcome_path

    assert_response :success
  end
end
