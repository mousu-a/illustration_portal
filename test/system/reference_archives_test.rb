require "application_system_test_case"

class ReferenceArchivesTest < ApplicationSystemTestCase
  test "空白区切りで複数タグを付けてブックマークを登録する" do
    visit reference_archives_path

    fill_in "ブックマークしたい画像のURL", with: "https://example.com/multi-tag"
    fill_in "ブックマークにつけるタグ", with: "背景 逆光"
    click_on "登録する"

    within ".timeline" do
      assert_text "https://example.com/multi-tag"
      assert_text "#背景"
      assert_text "#逆光"
    end
  end

  test "ブックマークのURLがリンクカードとして展開される" do
    metadata = { title: "リンクカードタイトル", image_url: "https://example.com/image.png", favicon_url: "https://example.com/favicon.ico" }

    LinkCard.stub(:fetch_metadata, metadata) do
      visit reference_archives_path

      fill_in "ブックマークしたい画像のURL", with: "https://example.com/article"
      click_on "登録する"

      within ".timeline" do
        assert_selector ".link-card"
        assert_text "リンクカードタイトル"
        assert_no_selector ".tweet__url"
      end
    end
  end

  test "存在しないURLはリンクカードとして展開されない" do
    LinkCard.stub(:fetch_metadata, nil) do
      visit reference_archives_path

      fill_in "ブックマークしたい画像のURL", with: "https://example.aabbcc/broken"
      click_on "登録する"

      within ".timeline" do
        assert_no_selector ".link-card"
        assert_link "https://example.aabbcc/broken"
      end
    end
  end

  # TODO ログイン後変更
  test "ブックマークを削除する" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/deleteme")
    visit reference_archives_path

    within "li.tweet", text: archive.url do
      accept_confirm { click_on "ブクマを外す" }
    end

    assert_no_text archive.url
  end

  # TODO ログイン後変更
  test "ブックマークを更新する" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/before")
    visit reference_archives_path

    within "li.tweet", text: archive.url do
      click_on "タグを編集"
      fill_in "URL", with: "https://example.com/after"
      click_on "更新する"
    end

    assert_text "https://example.com/after"
    assert_no_text "https://example.com/before"
  end

  # TODO ログイン後変更
  test "タグによりブックマークを絞り込む(AND)" do
    both = dev_user.reference_archives.create!(url: "https://example.com/both", tag_list: "ruby, rails")
    ruby_only = dev_user.reference_archives.create!(url: "https://example.com/ruby-only", tag_list: "ruby")
    unrelated = dev_user.reference_archives.create!(url: "https://example.com/unrelated", tag_list: "illustration")

    visit reference_archives_path

    find(".sidebar [data-tag-name='ruby']").click
    assert_text both.url
    assert_text ruby_only.url
    assert_no_text unrelated.url

    find(".sidebar [data-tag-name='rails']").click
    assert_text both.url
    assert_no_text ruby_only.url
    assert_no_text unrelated.url

    assert_current_path reference_archives_path(tags: [ "ruby", "rails" ])
  end

  # TODO ログイン後変更
  test "絞り込み中のタグを1つずつ解除する" do
    both = dev_user.reference_archives.create!(url: "https://example.com/both", tag_list: "ruby, rails")
    ruby_only = dev_user.reference_archives.create!(url: "https://example.com/ruby-only", tag_list: "ruby")

    visit reference_archives_path(tags: [ "ruby", "rails" ])

    within ".tag-filter-display" do
      find("[data-tag-name='rails']").click
    end
    assert_current_path reference_archives_path(tags: [ "ruby" ])

    within ".tag-filter-display" do
      find("[data-tag-name='ruby']").click
    end
    assert_no_selector ".tag-filter-display"
    assert_current_path reference_archives_path
    assert_text both.url
    assert_text ruby_only.url
  end

  # TODO ログイン後変更
  test "絞り込み中のタグを一括で解除する" do
    both = dev_user.reference_archives.create!(url: "https://example.com/both", tag_list: "ruby, rails")
    unrelated = dev_user.reference_archives.create!(url: "https://example.com/unrelated", tag_list: "illustration")

    visit reference_archives_path(tags: [ "ruby", "rails" ])
    assert_text both.url
    assert_no_text unrelated.url

    click_on "タグによる絞り込みを全解除"

    assert_no_selector ".tag-filter-display"
    assert_current_path reference_archives_path
    assert_text both.url
    assert_text unrelated.url
  end

  # TODO ログイン後変更
  test "タグの絞り込みをしても、関係のない部分はリロードされない" do
    dev_user.reference_archives.create!(url: "https://example.com/ruby", tag_list: "ruby")
    visit reference_archives_path

    fill_in "ブックマークしたい画像のURL", with: "https://example.com/not-submitted-yet"

    find(".sidebar [data-tag-name='ruby']").click

    assert_current_path reference_archives_path(tags: [ "ruby" ])
    assert_field "ブックマークしたい画像のURL", with: "https://example.com/not-submitted-yet"
  end

  # TODO ログイン後変更
  test "フォームのエラーメッセージ表示は、別のブックマークを登録・更新・削除するとリセットされる" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/to-delete")
    error_message = "URLを入力してください"

    visit reference_archives_path

    click_on "登録する"
    assert_text error_message
    within "li.tweet", text: archive.url do
      accept_confirm { click_on "ブクマを外す" }
    end
    assert_text "削除しました"
    assert_no_text error_message

    click_on "登録する"
    assert_text error_message
    fill_in "ブックマークしたい画像のURL", with: "https://example.com/new-bookmark"
    click_on "登録する"
    assert_text "保存しました"
    assert_no_text error_message

    click_on "登録する"
    assert_text error_message
    within "li.tweet", text: "https://example.com/new-bookmark" do
      click_on "タグを編集"
      fill_in "URL", with: "https://example.com/updated-bookmark"
      click_on "更新する"
    end
    assert_text "更新しました"
    assert_no_text error_message
  end
end
