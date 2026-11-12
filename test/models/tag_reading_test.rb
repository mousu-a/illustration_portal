require "test_helper"

class TagReadingTest < ActiveSupport::TestCase
  setup do
    @archive = reference_archives(:yamada_bookmark)
  end

  test "タグを保存すると読みが自動で入る" do
    @archive.update!(tag_list: [ "背景" ])

    assert_equal "はいけい", ActsAsTaggableOn::Tag.find_by!(name: "背景").reading
  end

  test "タグ名を変えると読みも作り直される" do
    tag = ActsAsTaggableOn::Tag.create!(name: "背景")
    tag.update!(name: "人物")

    assert_equal "じんぶつ", tag.reload.reading
  end

  test "読みが空のタグは保存時に補われる" do
    tag = ActsAsTaggableOn::Tag.create!(name: "背景")
    tag.update_column(:reading, nil)
    tag.update!(taggings_count: 1)

    assert_equal "はいけい", tag.reload.reading
  end

  test "名前が同じなら手で直した読みは上書きしない" do
    tag = ActsAsTaggableOn::Tag.create!(name: "背景")
    tag.update!(reading: "せかい")

    assert_equal "せかい", tag.reload.reading
  end
end
