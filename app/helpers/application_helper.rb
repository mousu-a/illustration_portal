module ApplicationHelper
  def default_meta_tags
    {
      site: "絵師ぽ！",
      reverse: true,
      separator: "|",
      charset: "utf-8",
      description: "絵を描く人のための資料ブックマークサービス。イラストや写真のブックマークをタグで整理して保存し、描きたいときにすぐ取り出せます。",
      keywords: %w[イラスト 資料 参考資料 ブックマーク タグ 絵描き お絵描き 絵師ぽ！],
      og: {
        title: :title,
        type: "website",
        site_name: "絵師ぽ！",
        description: :description,
        # TODO  ロゴ、ドメインを用意次第変更
        image: image_url("/icon.png"),
        url: request.original_url,
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        site: "@mousu_a"
      }
    }
  end
end
