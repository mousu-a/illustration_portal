class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.references :reference_archive, null: false, foreign_key: true, index: false
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :taggings, [ :reference_archive_id, :tag_id ], unique: true
  end
end
