require "test_helper"

class MetaTagsRequestTest < ActionDispatch::IntegrationTest
  test "GET / ウェルカムページのtitle・description・keywordsを出力する" do
    get root_path

    assert_select "title", "絵師ぽ！"
    assert_select "meta[name='description'][content^='絵を描く人のための資料ブックマークサービス。']"
    assert_select "meta[name='keywords'][content*='イラスト']"
  end

  test "GET /reference_archives ブックマーク一覧のtitle・descriptionを出力する" do
    login(users(:tanaka))

    get reference_archives_path

    assert_select "title", "ブックマーク登録、一覧ページ | 絵師ぽ！"
    assert_select "meta[name='description'][content^='保存したイラスト資料のブックマーク一覧。']"
  end
end
