class DropLegacyTagsAndTaggingsTables < ActiveRecord::Migration[8.1]
  def change
    # taggings は reference_archives / tags への外部キーを持つため先にdrop
    # if_exists: true … 開発環境によっては手動操作等でテーブルが既に存在しないケースがあるため
    drop_table :taggings, if_exists: true do |t|
      t.references :reference_archive, null: false, foreign_key: true, index: false
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    drop_table :tags, if_exists: true do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
