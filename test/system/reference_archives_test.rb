require "application_system_test_case"

class ReferenceArchivesTest < ApplicationSystemTestCase
  setup do
    @user = users(:tanaka)
    login(@user)
  end

  test "空白区切りで複数タグを付けてブックマークを登録する" do
    visit reference_archives_path

    fill_in "ブックマークしたい画像のURL", with: "https://example.com/multi-tag"
    fill_in "ブックマークにつけるタグ", with: "背景 逆光"
    click_on "登録する"

    within ".archives" do
      assert_text "https://example.com/multi-tag"
      assert_text "#背景"
      assert_text "#逆光"
    end
  end

  test "タグ入力欄にフォーカスするとタグのサジェストが表示される" do
    @user.reference_archives.create!(url: "https://example.com/ruby", tag_list: "ruby")

    visit reference_archives_path
    assert_no_selector ".tag-suggestions"

    find_field("ブックマークにつけるタグ").click
    assert_selector ".tag-suggestions", text: "#ruby"
  end

  test "URLを入力すると登録ボタンが押せるようになる" do
    visit reference_archives_path
    assert_button "登録する", disabled: true

    fill_in "ブックマークしたい画像のURL", with: "https://example.com/enable"
    assert_button "登録する", disabled: false
  end

  test "URLを入力すると元サイトでのいいねやリツイート（評価）をリマインドする" do
    visit reference_archives_path
    assert_no_text "いいねやリツイート（評価）も忘れずに！"

    fill_in "ブックマークしたい画像のURL", with: "https://example.com/reminder"
    assert_text "いいねやリツイート（評価）も忘れずに！"
  end

  test "ペーストボタンを押すとクリップボードの内容がURL欄に入る" do
    visit reference_archives_path
    page.execute_script("navigator.clipboard.readText = () => Promise.resolve('https://example.com/pasted')")

    click_on "クリップボードから貼り付け"

    assert_field "ブックマークしたい画像のURL", with: "https://example.com/pasted"
    assert_button "登録する", disabled: false
  end

  test "ブックマークのURLがリンクカードとして展開される" do
    metadata = { title: "リンクカードタイトル", image_url: "https://example.com/image.png", favicon_url: "https://example.com/favicon.ico" }

    LinkCard.stub(:fetch_metadata, metadata) do
      visit reference_archives_path

      fill_in "ブックマークしたい画像のURL", with: "https://example.com/article"
      click_on "登録する"

      within ".archives" do
        assert_selector ".link-card"
        assert_text "リンクカードタイトル"
        assert_no_selector ".archive__url"
      end
    end
  end

  test "存在しないURLはリンクカードとして展開されない" do
    LinkCard.stub(:fetch_metadata, nil) do
      visit reference_archives_path

      fill_in "ブックマークしたい画像のURL", with: "https://example.aabbcc/broken"
      click_on "登録する"

      within ".archives" do
        assert_no_selector ".link-card"
        assert_link "https://example.aabbcc/broken"
      end
    end
  end

  test "ブックマークを削除する" do
    archive = @user.reference_archives.create!(url: "https://example.com/deleteme")
    visit reference_archives_path

    within "li.archive", text: archive.url do
      find("button[aria-label='メニュー']").click
      accept_confirm { click_on "ブクマを外す" }
    end

    assert_no_text archive.url
  end

  test "ブックマークを更新する" do
    archive = @user.reference_archives.create!(url: "https://example.com/before")
    visit reference_archives_path

    within "li.archive", text: archive.url do
      find("button[aria-label='メニュー']").click
      click_on "タグを編集"
      fill_in "URL", with: "https://example.com/after"
      click_on "更新する"
    end

    assert_text "https://example.com/after"
    assert_no_text "https://example.com/before"
  end

  test "タグをクリックすると、絞り込むタグを切り替えられる" do
    has_tag_a = @user.reference_archives.create!(url: "https://example.com/has-tag-a", tag_list: "tag_a")
    has_tag_b = @user.reference_archives.create!(url: "https://example.com/has-tag-b", tag_list: "tag_b")

    visit reference_archives_path

    find(".sidebar__tag", text: "#tag_a").click
    assert_text has_tag_a.url
    assert_no_text has_tag_b.url

    find(".sidebar__tag", text: "#tag_b").click
    assert_text has_tag_b.url
    assert_no_text has_tag_a.url
    assert_current_path reference_archives_path(tags: [ "tag_b" ])
  end

  test "「さらにタグを追加して絞り込む」をONに(クリック)すると、タグをクリックすると絞り込み条件(AND)に追加されるようになる" do
    has_both_tags = @user.reference_archives.create!(url: "https://example.com/has-both-tags", tag_list: "tag_a, tag_b")
    has_one_tag = @user.reference_archives.create!(url: "https://example.com/has-one-tag", tag_list: "tag_a")

    visit reference_archives_path
    find(".sidebar__tag", text: "#tag_a").click
    assert_text has_one_tag.url

    click_on "さらにタグを追加して絞り込む"
    assert_selector ".tag-filter__add-mode[aria-pressed='true']"

    find(".sidebar__tag", text: "#tag_b").click
    assert_text has_both_tags.url
    assert_no_text has_one_tag.url
    assert_current_path reference_archives_path(tags: [ "tag_a", "tag_b" ])
  end

  test "「さらにタグを追加して絞り込む」モードは、もう一度押すか絞り込みのタグをクリアするとOFFになる" do
    @user.reference_archives.create!(url: "https://example.com/tag-a", tag_list: "tag_a")

    visit reference_archives_path(tags: [ "tag_a" ])

    click_on "さらにタグを追加して絞り込む"
    assert_selector ".tag-filter__add-mode[aria-pressed='true']"
    click_on "さらにタグを追加して絞り込む"
    assert_selector ".tag-filter__add-mode[aria-pressed='false']"

    click_on "さらにタグを追加して絞り込む"
    assert_selector ".tag-filter__add-mode[aria-pressed='true']"
    click_on "タグの絞り込みをクリア"
    assert_no_selector ".tag-filter"
  end

  test "絞り込み中のタグを1つずつ解除する" do
    both = @user.reference_archives.create!(url: "https://example.com/both", tag_list: "ruby, rails")
    ruby_only = @user.reference_archives.create!(url: "https://example.com/ruby-only", tag_list: "ruby")

    visit reference_archives_path(tags: [ "ruby", "rails" ])

    within ".tag-filter" do
      find(".tag-filter__selected-tag", text: "#rails").click
    end
    assert_current_path reference_archives_path(tags: [ "ruby" ])

    within ".tag-filter" do
      find(".tag-filter__selected-tag", text: "#ruby").click
    end
    assert_no_selector ".tag-filter"
    assert_current_path reference_archives_path
    assert_text both.url
    assert_text ruby_only.url
  end

  test "絞り込み中のタグを一括で解除する" do
    both = @user.reference_archives.create!(url: "https://example.com/both", tag_list: "ruby, rails")
    unrelated = @user.reference_archives.create!(url: "https://example.com/unrelated", tag_list: "illustration")

    visit reference_archives_path(tags: [ "ruby", "rails" ])
    assert_text both.url
    assert_no_text unrelated.url

    click_on "タグの絞り込みをクリア"

    assert_no_selector ".tag-filter"
    assert_current_path reference_archives_path
    assert_text both.url
    assert_text unrelated.url
  end

  test "タグの絞り込みをしても、関係のない部分はリロードされない" do
    @user.reference_archives.create!(url: "https://example.com/ruby", tag_list: "ruby")
    visit reference_archives_path

    fill_in "ブックマークしたい画像のURL", with: "https://example.com/not-submitted-yet"

    find(".sidebar__tag", text: "#ruby").click

    assert_current_path reference_archives_path(tags: [ "ruby" ])
    assert_field "ブックマークしたい画像のURL", with: "https://example.com/not-submitted-yet"
  end

  test "フォームのエラーメッセージ表示は、別のブックマークを登録・更新・削除するとリセットされる" do
    archive = @user.reference_archives.create!(url: "https://example.com/to-delete")
    error_message = "URLは http:// または https:// で始まる形式のものしか受け付けていません"

    visit reference_archives_path

    fill_in "ブックマークしたい画像のURL", with: "not-a-url"
    click_on "登録する"
    assert_text error_message
    within "li.archive", text: archive.url do
      find("button[aria-label='メニュー']").click
      accept_confirm { click_on "ブクマを外す" }
    end
    assert_text "削除しました"
    assert_no_text error_message

    fill_in "ブックマークしたい画像のURL", with: "not-a-url"
    click_on "登録する"
    assert_text error_message
    fill_in "ブックマークしたい画像のURL", with: "https://example.com/new-bookmark"
    click_on "登録する"
    assert_text "保存しました"
    assert_no_text error_message

    fill_in "ブックマークしたい画像のURL", with: "not-a-url"
    click_on "登録する"
    assert_text error_message
    within "li.archive", text: "https://example.com/new-bookmark" do
      find("button[aria-label='メニュー']").click
      click_on "タグを編集"
      fill_in "URL", with: "https://example.com/updated-bookmark"
      click_on "更新する"
    end
    assert_text "更新しました"
    assert_no_text error_message
  end

  test "狭い画面ではサイドバーをハンバーガーメニューとしてたたむ" do
    page.current_window.resize_to(800, 1000)

    visit reference_archives_path
    assert_no_selector ".sidebar"

    click_on "メニューを開く"
    assert_selector ".sidebar"

    click_on "メニューを閉じる"
    assert_no_selector ".sidebar"
  ensure
    page.current_window.resize_to(1400, 1400)
  end
end
