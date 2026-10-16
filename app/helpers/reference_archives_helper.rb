module ReferenceArchivesHelper
  KANA_ROWS = {
    "あ" => "あいうえお",
    "か" => "かきくけこ",
    "さ" => "さしすせそ",
    "た" => "たちつてと",
    "な" => "なにぬねの",
    "は" => "はひふへほ",
    "ま" => "まみむめも",
    "や" => "やゆよ",
    "ら" => "らりるれろ",
    "わ" => "わをん"
  }.freeze
  KANA_OTHER_GROUP = "その他".freeze

  # バリデでPOST失敗時、該当インスタンスのみ、バリデの失敗で初期化された@reference_archiveに差し替える
  # (繰り返し表示に使われる @reference_archives は、turbo_streamで一覧を再描画する際にDBから取得し直した値で、失敗時のエラー情報を持たないため)
  def edit_target_for(archive)
    valid_error_record = @reference_archive
    return valid_error_record if valid_error_record && valid_error_record.id == archive.id

    archive
  end

  def tag_select_paths(tag_name, current_selected_tags:)
    {
      add_href: reference_archives_path(tags: (current_selected_tags + [ tag_name ]).uniq),
      switch_href: reference_archives_path(tags: [ tag_name ])
    }
  end

  def tag_deselect_path(remove_tag, current_selected_tags:)
    remaining_tags = current_selected_tags - [ remove_tag ]
    remaining_tags.present? ? reference_archives_path(tags: remaining_tags) : reference_archives_path
  end

  def sort_for_suggestions(tags)
    tags.sort_by { |tag| [ -tag.count, tag.name ] }
  end

  def group_tags_by_kana(tags)
    group_tags = (KANA_ROWS.keys + [ KANA_OTHER_GROUP ]).index_with { [] }
    tags.sort_by(&:name).each do |tag|
      kana_row = kana_row_of(tag.name)
      group_tags[kana_row] << tag
    end
    group_tags
  end

  def kana_row_of(name)
    first_char = name.unicode_normalize(:nfkc)[0]
    normalized_first_char = first_char.tr("ァ-ヶ", "ぁ-ゖ").unicode_normalize(:nfd).delete("゙゚").tr("ぁぃぅぇぉっゃゅょゎゕゖ", "あいうえおつやゆよわかけ")
    KANA_ROWS.keys.find { |row| KANA_ROWS[row].include?(normalized_first_char) } || KANA_OTHER_GROUP
  end
end
