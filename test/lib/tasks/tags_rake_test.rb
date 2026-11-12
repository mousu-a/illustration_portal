require "test_helper"
require "rake"

class TagsRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("tags:backfill_reading")
    Rake::Task["tags:backfill_reading"].reenable
  end

  test "読みが空のタグだけ埋める" do
    empty = ActsAsTaggableOn::Tag.create!(name: "背景")
    empty.update_column(:reading, nil)
    manual = ActsAsTaggableOn::Tag.create!(name: "人物")
    manual.update_column(:reading, "ひと")

    capture_io { Rake::Task["tags:backfill_reading"].invoke }

    assert_equal "はいけい", empty.reload.reading
    assert_equal "ひと", manual.reload.reading
  end

  test "もう一度実行しても結果は変わらない" do
    tag = ActsAsTaggableOn::Tag.create!(name: "背景")
    tag.update_column(:reading, nil)

    capture_io { Rake::Task["tags:backfill_reading"].invoke }
    Rake::Task["tags:backfill_reading"].reenable
    capture_io { Rake::Task["tags:backfill_reading"].invoke }

    assert_equal "はいけい", tag.reload.reading
  end
end
