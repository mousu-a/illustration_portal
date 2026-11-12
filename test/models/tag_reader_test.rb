require "test_helper"

class TagReaderTest < ActiveSupport::TestCase
  test "漢字の読みをひらがなで返す" do
    assert_equal "はいけい", TagReader.call("背景")
  end

  test "カタカナはひらがなに揃える" do
    assert_equal "いらすと", TagReader.call("イラスト")
  end

  test "漢字とカタカナが混ざっていても読める" do
    assert_equal "はいけいいらすと", TagReader.call("背景イラスト")
  end

  test "全角英数は半角小文字に揃える" do
    assert_equal "abc123", TagReader.call("ＡＢＣ１２３")
  end

  test "辞書にない語は表層形をそのまま使う" do
    assert_equal "xyzqw", TagReader.call("xyzqw")
  end

  test "空文字は空文字を返す" do
    assert_equal "", TagReader.call("")
  end
end
