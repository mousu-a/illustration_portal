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

  test "#sort_for_suggestions タグを使用数の多い順、同数なら名前順に並べて返す" do
    user = users(:tanaka)
    user.reference_archives.create!(url: "https://example.com/1", tag_list: "イラスト, ポーズ, ラフ")
    user.reference_archives.create!(url: "https://example.com/2", tag_list: "イラスト")

    tags = user.reference_archives.tag_counts_on(:tags)
    result = sort_for_suggestions(tags)

    assert_equal [ "イラスト", "ポーズ", "ラフ" ], result.map(&:name)
  end

  test "#sort_for_suggestions タグが無い場合は空配列を返す" do
    tags = users(:tanaka).reference_archives.tag_counts_on(:tags)

    assert_equal [], sort_for_suggestions(tags)
  end

  test "#group_tags_by_kana 先頭の仮名（あかさたな〜わ、その他）でグループ化したハッシュを返す" do
    tags = [ "かめら", "ガーデン", "あお", "ポーズ", "ぱん" ].map { |name| ActsAsTaggableOn::Tag.new(name: name) }
    result = group_tags_by_kana(tags)

    assert_equal [ "あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "その他" ], result.keys
    assert_equal [ "あお" ], result["あ"].map(&:name)
    assert_equal [ "かめら", "ガーデン" ], result["か"].map(&:name)
    assert_equal [ "ぱん", "ポーズ" ], result["は"].map(&:name)
  end

  test "#group_tags_by_kana まだタグが無い行は空配列を返す" do
    tags = [ "あお" ].map { |name| ActsAsTaggableOn::Tag.new(name: name) }
    result = group_tags_by_kana(tags)

    assert_equal [ "あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ", "その他" ], result.keys
    assert_equal [ "あお" ], result["あ"].map(&:name)
    assert_equal [], result["さ"]
  end

  test "#group_tags_by_kana 小書き文字は通常の文字として扱う" do
    tags = [ "ヵ", "ヶ" ].map { |name| ActsAsTaggableOn::Tag.new(name: name) }
    result = group_tags_by_kana(tags)

    assert_equal [ "ヵ", "ヶ" ], result["か"].map(&:name)
  end

  test "#group_tags_by_kana 漢字・英数字は「その他」にまとめる" do
    tags = [ "ruby", "あお", "顔" ].map { |name| ActsAsTaggableOn::Tag.new(name: name) }
    result = group_tags_by_kana(tags)

    assert_equal [ "ruby", "顔" ], result["その他"].map(&:name)
  end

  test "#kana_row_of 先頭の文字が属する仮名を返す" do
    assert_equal "あ", kana_row_of("あお")
    assert_equal "か", kana_row_of("カメラ")
    assert_equal "か", kana_row_of("ガーデン")
    assert_equal "は", kana_row_of("ぱん")
    assert_equal "は", kana_row_of("ﾎﾟｰｽﾞ")
    assert_equal "わ", kana_row_of("ゎああ")
  end

  test "#kana_row_of 漢字・英数字は「その他」として扱う" do
    assert_equal "その他", kana_row_of("ruby")
    assert_equal "その他", kana_row_of("顔")
  end
end
