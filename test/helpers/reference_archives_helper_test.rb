require "test_helper"

class ReferenceArchivesHelperTest < ActionView::TestCase
  test "#edit_target_for 通常の一覧表示時は、渡されたインスタンスをそのまま返す" do
    @reference_archive = reference_archives(:yamada_bookmark)
    @reference_archive.update(url: "https://example.com/success")

    @reference_archives = ReferenceArchive.all
    archive_in_list = @reference_archives.find(@reference_archive.id)

    assert_equal archive_in_list, edit_target_for(@reference_archive)
    assert_not_same @reference_archive, archive_in_list
  end

  test "#edit_target_for POST失敗時は、該当インスタンスをエラーの格納されているインスタンスに差し替える" do
    @reference_archive = reference_archives(:yamada_bookmark)
    @reference_archive.update(url: "")

    @reference_archives = ReferenceArchive.all
    archive_in_list = @reference_archives.find(@reference_archive.id)

    assert_equal archive_in_list, edit_target_for(@reference_archive)
    assert_same @reference_archive, edit_target_for(archive_in_list)
  end

  test "#selected_tags_path 選択中タグに新しいタグを加えたパスを返す" do
    result = selected_tags_path("ruby", current_selected_tags: [ "rails" ])

    assert_equal reference_archives_path(tags: [ "rails", "ruby" ]), result
  end

  test "#selected_tags_path 既に選択済みのタグを渡した場合は重複させない" do
    result = selected_tags_path("rails", current_selected_tags: [ "rails", "ruby" ])

    assert_equal reference_archives_path(tags: [ "rails", "ruby" ]), result
  end

  test "#tag_deselect_path 指定したタグを除いた残りのタグでパスを返す" do
    result = tag_deselect_path("rails", current_selected_tags: [ "rails", "ruby" ])

    assert_equal reference_archives_path(tags: [ "ruby" ]), result
  end

  test "#tag_deselect_path 最後の1つを除去した場合はタグなしのパスを返す" do
    result = tag_deselect_path("rails", current_selected_tags: [ "rails" ])

    assert_equal reference_archives_path, result
  end
end
