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

  test "タグのサジェストは使用数の多い順に10件まで表示する" do
    find_field("ブックマークにつけるタグ").click

    within ".tag-suggestions" do
      assert_selector ".tag-label", count: 10
      assert_no_text "#11個目の登録数が一番少ないタグ"
    end
  end

  test "タグ入力中の語にタグをサジェスト(ひらがな・カタカナを問わずマッチする)し、クリックすると入力中の語を補完する" do
    fill_in "ブックマークにつけるタグ", with: "背景 いら"

    within ".tag-suggestions" do
      assert_text "#イラスト"
      assert_no_text "#ruby"
      click_on "#イラスト"
    end
    assert_field "ブックマークにつけるタグ", with: "背景 イラスト "

    assert_selector ".tag-suggestions"
    assert_no_selector ".tag-suggestions .tag-label"
  end

  test "タグ入力中の語に一致するタグが無ければサジェストは表示しない" do
    fill_in "ブックマークにつけるタグ", with: "zzz"

    assert_no_selector ".tag-suggestions .tag-label"
  end

  test "タグ検索はひらがな・カタカナを問わずマッチする" do
    fill_in "タグを検索", with: "らふ"

    assert_selector ".sidebar__tag", text: "#ラフ"
  end

  test "タグ検索中は五十音グループの表示を隠し、ヒットしたタグを保存数の多い順に表示する 検索バーが空になると五十音表示に戻る" do
    user = users(:tanaka)
    2.times { |i| user.reference_archives.create!(url: "https://example.com/sketch-#{i}", tag_list: "sketch") }
    user.reference_archives.create!(url: "https://example.com/asketch", tag_list: "asketch")

    visit reference_archives_path
    fill_in "タグを検索", with: "sketch"

    assert_text "ヒットしたタグ"
    result_tags = all(".sidebar__search-results .sidebar__tag")
    assert_equal "#sketch (2)", result_tags[0].text
    assert_equal "#asketch (1)", result_tags[1].text
    assert_no_selector ".sidebar__tag-group-title"

    fill_in "タグを検索", with: ""

    assert_selector ".sidebar__tag-group-title"
    assert_no_text "ヒットしたタグ"
  end

  test "タグ検索は一致しなければ「ヒットするタグがありませんでした」を表示する" do
    assert_no_text "ヒットするタグがありませんでした"

    fill_in "タグを検索", with: "zzz"

    assert_no_selector ".sidebar__tag"
    assert_text "ヒットするタグがありませんでした"
    assert_no_text "ヒットしたタグ"
  end
end
