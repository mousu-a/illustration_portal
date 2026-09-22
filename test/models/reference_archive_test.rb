require "test_helper"

class ReferenceArchiveTest < ActiveSupport::TestCase
  setup do
    @user = users(:yamada)
  end

  test ".filtered_by_tags タグが未指定の場合タグによる絞り込みを行わず、ユーザーの全レコードを返す" do
    archive = ReferenceArchive.create!(user: @user, url: "https://example.com/a", tag_list: "ruby")

    assert_includes ReferenceArchive.where(user: @user).filtered_by_tags(nil), archive
    assert_includes ReferenceArchive.where(user: @user).filtered_by_tags([]), archive
  end

  test ".filtered_by_tags タグが指定されている場合、指定タグを全て持つ（AND）レコードのみ返す" do
    exact = ReferenceArchive.create!(user: @user, url: "https://example.com/matched", tag_list: "ruby, rails")
    partial = ReferenceArchive.create!(user: @user, url: "https://example.com/partial", tag_list: "ruby")

    result = ReferenceArchive.where(user: @user).filtered_by_tags([ "ruby", "rails" ])

    assert_includes result, exact
    assert_not_includes result, partial
  end

  test "#create_message 保存したブックマークが現在の絞り込み条件と一致する場合、通常の保存メッセージを返す" do
    reference_archive = ReferenceArchive.new(user: @user, url: "https://example.com/x", tag_list: "ruby")

    assert_equal "保存しました", reference_archive.create_message([ "ruby" ])
  end

  test "#create_message 保存したブックマークが現在の絞り込み条件と一致しない場合、一覧の表示対象外である旨のメッセージを返す" do
    reference_archive = ReferenceArchive.new(user: @user, url: "https://example.com/x", tag_list: "ruby")

    assert_equal "保存しました（現在の絞り込み条件と一致しないため、この一覧には表示されていません）",
                 reference_archive.create_message([ "ruby", "rails" ])
  end

  test "#included_in_tag_filter? タグが未指定の場合 true を返す" do
    reference_archive = ReferenceArchive.new(user: @user, url: "https://example.com/x", tag_list: "ruby")

    assert reference_archive.included_in_tag_filter?(nil)
    assert reference_archive.included_in_tag_filter?([])
  end

  test "#included_in_tag_filter? タグが指定されている場合、archive が指定タグを全て持っていれば true を返す" do
    reference_archive = ReferenceArchive.new(user: @user, url: "https://example.com/x", tag_list: "ruby, rails")

    assert reference_archive.included_in_tag_filter?([ "ruby", "rails" ])
  end

  test "#included_in_tag_filter? タグが指定されている場合、絞り込みのタグにarchive が持たない指定タグが含まれていれば false を返す" do
    reference_archive = ReferenceArchive.new(user: @user, url: "https://example.com/x", tag_list: "ruby")

    assert_not reference_archive.included_in_tag_filter?([ "ruby", "rails" ])
  end
end
