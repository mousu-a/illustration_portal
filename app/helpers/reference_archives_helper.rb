module ReferenceArchivesHelper
  # バリデでPOST失敗時、該当インスタンスのみ、バリデの失敗で初期化された@reference_archiveに差し替える
  # (繰り返し表示に使われる @reference_archives は、turbo_streamで一覧を再描画する際にDBから取得し直した値で、失敗時のエラー情報を持たないため)
  def edit_target_for(archive)
    valid_error_record = @reference_archive
    return valid_error_record if valid_error_record && valid_error_record.id == archive.id

    archive
  end

  def selected_tags_path(append_tag, current_selected_tags:)
    reference_archives_path(tags: (current_selected_tags + [ append_tag ]).uniq)
  end

  def tag_deselect_path(remove_tag, current_selected_tags:)
    remaining_tags = current_selected_tags - [ remove_tag ]
    remaining_tags.present? ? reference_archives_path(tags: remaining_tags) : reference_archives_path
  end
end
