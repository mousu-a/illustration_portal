require "test_helper"

class ReferenceArchivesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:tanaka)
    @other_user = users(:sato)
    login(@user)
  end

  test "#index 未ログインの場合はトップページへリダイレクトする" do
    delete logout_path

    get reference_archives_path

    assert_redirected_to root_path
  end

  test "index はブックマークが1件も無いとき空メッセージを表示する" do
    get reference_archives_path

    assert_response :success
    assert_match "ブックマークが見つからないようです", response.body
  end

  # TODO ログイン後変更
  test "index はタグ絞り込みでヒットしないとき空メッセージを表示する" do
    dev_user.reference_archives.create!(url: "https://example.com/no-match", tag_list: "illustration")

    get reference_archives_path, params: { tags: [ "nonexistent" ] }

    assert_response :success
    assert_match "ブックマークが見つからないようです", response.body
  end

  # TODO ログイン後変更
  test "index は自分のブックマークのみ表示する" do
    mine = dev_user.reference_archives.create!(url: "https://example.com/mine")
    others = @other_user.reference_archives.create!(url: "https://example.com/others")

    get reference_archives_path

    assert_response :success
    assert_match mine.url, response.body
    assert_no_match others.url, response.body
  end

  # TODO ログイン後変更
  test "index はタグでAND絞り込みできる" do
    exact = dev_user.reference_archives.create!(url: "https://example.com/matched", tag_list: "ruby, rails")
    partial = dev_user.reference_archives.create!(url: "https://example.com/partial", tag_list: "ruby")

    get reference_archives_path, params: { tags: [ "ruby", "rails" ] }

    assert_response :success
    assert_match exact.url, response.body
    assert_no_match partial.url, response.body
  end

  # TODO ログイン後変更
  test "create で保存できる" do
    assert_difference("ReferenceArchive.count", 1) do
      post reference_archives_path, params: { reference_archive: { url: "https://example.com/new", tag_list: [ "illustration" ] } }
    end

    assert_redirected_to reference_archives_path
    assert_equal [ "illustration" ], dev_user.reference_archives.last.tags.pluck(:name)
  end

  test "create成功時、リダイレクトしても絞り込み中のタグを維持している" do
    new_archive_params = { url: "https://example.com/new", tag_list: [ "illustration" ] }
    current_selected_tags = [ "ruby" ]

    post reference_archives_path, params: {
      reference_archive: new_archive_params,
      tags: current_selected_tags
    }

    assert_redirected_to reference_archives_path(tags: current_selected_tags)
  end

  test "create成功時、createしたブクマが現在の絞り込み中のタグに一致しない場合は、一覧には表示されていない旨をフラッシュで表示する" do
    post reference_archives_path,
      params: {
        reference_archive: { url: "https://example.com/no-match", tag_list: [ "illustration" ] },
        tags: [ "ruby" ]
      },
      as: :turbo_stream

    assert_no_turbo_stream action: "prepend", target: "timeline_list"
    assert_turbo_stream action: "update", target: "flash"
    assert_match "保存しました（現在の絞り込み条件と一致しないため、この一覧には表示されていません）", response.body
  end

  test "create は url が空だと失敗する" do
    assert_no_difference("ReferenceArchive.count") do
      post reference_archives_path, params: { reference_archive: { url: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors"
  end

  # TODO ログイン後変更
  test "create成功時、一覧の先頭に追加する" do
    dev_user.reference_archives.create!(url: "https://example.com/existing")

    assert_difference("ReferenceArchive.count", 1) do
      post reference_archives_path,
        params: { reference_archive: { url: "https://example.com/new", tag_list: [ "illustration" ] } },
        as: :turbo_stream
    end

    assert_turbo_stream action: "prepend", target: "timeline_list"
    assert_match "https://example.com/new", response.body
    assert_match "保存しました", response.body
  end

  test "create成功時、一覧の先頭に追加し、空メッセージをremoveする" do
    post reference_archives_path,
      params: { reference_archive: { url: "https://example.com/first" } },
      as: :turbo_stream

    assert_turbo_stream action: "remove", target: "timeline_empty"
    assert_turbo_stream action: "prepend", target: "timeline_list"
    assert_match "https://example.com/first", response.body
  end

  test "create失敗時、formにエラー内容を表示する" do
    post reference_archives_path, params: { reference_archive: { url: "" } }, as: :turbo_stream

    assert_turbo_stream status: :unprocessable_entity, action: "replace", target: "composer"
    assert_match "form-errors", response.body
  end

  # TODO ログイン後変更
  test "update で自分のブックマークを更新できる" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/before")

    patch reference_archive_path(archive), params: { reference_archive: { url: "https://example.com/after" } }

    assert_redirected_to reference_archives_path
    assert_equal "https://example.com/after", archive.reload.url
  end

  test "他ユーザーのブックマークはupdateできない" do
    archive = @other_user.reference_archives.create!(url: "https://example.com/others")

    patch reference_archive_path(archive), params: { reference_archive: { url: "https://example.com/changed" } }

    assert_response :not_found
    assert_equal "https://example.com/others", archive.reload.url
  end

  # TODO ログイン後変更
  test "update は url が空だと失敗する" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/before")

    patch reference_archive_path(archive), params: { reference_archive: { url: "" } }

    assert_response :unprocessable_entity
    assert_equal "https://example.com/before", archive.reload.url
  end

  # TODO ログイン後変更
  test "update成功時、該当のレコードをreplaceする" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/before")

    patch reference_archive_path(archive),
      params: { reference_archive: { url: "https://example.com/after" } },
      as: :turbo_stream

    assert_turbo_stream action: "replace", target: archive
    assert_match "https://example.com/after", response.body
    assert_match "更新しました", response.body
  end

  # TODO ログイン後変更
  test "update失敗時、該当のレコードでformエラーを表示する" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/before")

    patch reference_archive_path(archive),
      params: { reference_archive: { url: "" } },
      as: :turbo_stream

    assert_turbo_stream status: :unprocessable_entity, action: "replace", target: archive
    assert_match "form-errors", response.body
  end

  # TODO ログイン後変更
  test "destroy で自分のブックマークを削除できる" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/deleteme")

    assert_difference("ReferenceArchive.count", -1) do
      delete reference_archive_path(archive)
    end

    assert_response :see_other
    assert_redirected_to reference_archives_path
  end

  test "他ユーザーのブックマークはdestroyできない" do
    archive = @other_user.reference_archives.create!(url: "https://example.com/others")

    assert_no_difference("ReferenceArchive.count") do
      delete reference_archive_path(archive)
    end

    assert_response :not_found
  end

  # TODO ログイン後変更
  test "destroy成功時、該当のレコードをremoveする" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/deleteme")

    assert_difference("ReferenceArchive.count", -1) do
      delete reference_archive_path(archive), as: :turbo_stream
    end

    assert_turbo_stream action: "remove", target: archive
    assert_match "削除しました", response.body
  end

  # TODO ログイン後変更
  test "destroy成功時、一覧が空になった場合は空メッセージを表示する" do
    archive = dev_user.reference_archives.create!(url: "https://example.com/deleteme")

    delete reference_archive_path(archive), as: :turbo_stream

    assert_turbo_stream action: "before", target: "timeline_list"
    assert_match "ブックマークが見つからないようです", response.body
  end
end
