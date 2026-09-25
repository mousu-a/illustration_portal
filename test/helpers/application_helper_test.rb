require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "#default_meta_tags サイト共通のmetaタグをハッシュで返す" do
    meta_tags = default_meta_tags

    assert_equal "絵師ぽ！", meta_tags[:site]
    assert_equal "絵を描く人のための資料ブックマークサービス。イラストや写真のブックマークをタグで整理して保存し、描きたいときにすぐ取り出せます。", meta_tags[:description]
  end

  test "#default_meta_tags OGPとTwitterカードのmetaタグを含む" do
    meta_tags = default_meta_tags

    assert_equal "絵師ぽ！", meta_tags[:og][:site_name]
    assert_equal "summary_large_image", meta_tags[:twitter][:card]
  end
end
