class AddReadingToTags < ActiveRecord::Migration[8.1]
  def change
    add_column :tags, :reading, :string
    add_index :tags, :reading
  end
end
