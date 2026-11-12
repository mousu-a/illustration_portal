# acts-as-taggable-on のタグ（gem 側のクラス）に、読み仮名の自動生成を追加する
Rails.application.config.to_prepare do
  ActsAsTaggableOn::Tag.include TagReading
end
