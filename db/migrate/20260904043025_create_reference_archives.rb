class CreateReferenceArchives < ActiveRecord::Migration[8.1]
  def change
    create_table :reference_archives do |t|
      t.references :user, null: false, foreign_key: true
      t.text :url, null: false

      t.timestamps
    end

    add_index :reference_archives, [ :user_id, :url ], unique: true
  end
end
