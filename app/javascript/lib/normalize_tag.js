export function normalizeTag(str) {
  return str
    .normalize("NFKC")
    // カタカナの場合ひらがなに変換
    .replace(/[ァ-ヶ]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0x60))
    .toLowerCase()
    .trim();
}
