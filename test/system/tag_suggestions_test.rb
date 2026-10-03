require "application_system_test_case"

class TagSuggestionsTest < ApplicationSystemTestCase
  setup do
    user = users(:tanaka)
    tag_list = "イラスト, ラフ, ruby, 背景, 逆光, 線画, 塗り, 構図, 配色, ポーズ"
    2.times { |i| user.reference_archives.create!(url: "https://example.com/popular-#{i}", tag_list:) }
    user.reference_archives.create!(url: "https://example.com", tag_list: "11個目の登録数が一番少ないタグ")

    login(user)
    visit reference_archives_path
  end

  test "タグ検索はひらがな・カタカナを問わずマッチする" do
    fill_in "タグを検索", with: "らふ"

    assert_selector ".sidebar [data-tag-name='ラフ']"
  end

  test "タグ検索は一致しなければタグを表示しない" do
    fill_in "タグを検索", with: "zzz"

    assert_no_selector ".sidebar [data-tag-name]"
  end
end
