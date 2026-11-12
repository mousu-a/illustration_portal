# タグ名から読み仮名（ひらがな）を生成する。
# lindera（同梱の IPADIC 辞書）で形態素解析し、各語の読みをつなげる。
# 比較しやすいよう、JS の normalizeTag と同じ規則（NFKC・カタカナ→ひらがな・小文字化）で揃える。
class TagReader
  DICTIONARY = "embedded://ipadic".freeze
  # IPADIC の品詞情報の並びのうち、読み（カタカナ）が入っている位置
  READING_INDEX = 7

  def self.call(name)
    new(name).call
  end

  # Tokenizer は構築コストが高いので、プロセス内で使い回す
  def self.tokenizer
    @tokenizer ||= Lindera::TokenizerBuilder.new.tap do |builder|
      builder.set_mode("normal")
      builder.set_dictionary(DICTIONARY)
    end.build
  end

  def initialize(name)
    @name = name.to_s
  end

  def call
    # 全角英数をそのまま解析すると「えいびーしー」のように読まれてしまうので、先に半角へ揃える
    source = @name.unicode_normalize(:nfkc).strip
    return "" if source.empty?

    normalize(self.class.tokenizer.tokenize(source).map { |token| reading_of(token) }.join)
  end

  private

  # 未知語は読みが "*" になる（または存在しない）ので、表層形で代用する
  def reading_of(token)
    reading = token.details&.at(READING_INDEX)
    reading.nil? || reading == "*" ? token.surface : reading
  end

  def normalize(text)
    text.unicode_normalize(:nfkc).tr("ァ-ヶ", "ぁ-ゖ").downcase.strip
  end
end
