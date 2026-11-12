# ActsAsTaggableOn::Tag に「読み仮名の自動生成」を足す。
# config/initializers/acts_as_taggable_on_reading.rb から include される。
module TagReading
  extend ActiveSupport::Concern

  included do
    before_save :assign_reading
  end

  private

  # 読みが空のとき、またはタグ名が変わったときに自動生成する。
  # reading を明示的に変更して保存する場合は、その値を優先する。
  def assign_reading
    return if will_save_change_to_reading? && reading.present?

    self.reading = TagReader.call(name) if reading.blank? || will_save_change_to_name?
  end
end
