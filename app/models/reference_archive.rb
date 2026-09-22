class ReferenceArchive < ApplicationRecord
  belongs_to :user
  acts_as_taggable_on :tags

  validates :url, presence: true, uniqueness: { scope: :user_id },
            format: { with: URI.regexp(%w[http https]), message: "は http:// または https:// で始まる形式のものしか受け付けていません" }

  scope :filtered_by_tags, ->(tags) {
    tags.present? ? tagged_with(tags) : all
  }

  def create_message(selected_tags)
    included_in_tag_filter?(selected_tags) ? "保存しました" : "保存しました（現在の絞り込み条件と一致しないため、この一覧には表示されていません）"
  end

  def included_in_tag_filter?(selected_tags)
    no_tags_selected = selected_tags.blank?
    return true if no_tags_selected

    selected_tags.all? { |tag| self.tag_list.include?(tag) }
  end
end
