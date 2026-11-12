export function normalizeTag(str) {
  return (
    str
      .normalize("NFKC")
      // カタカナの場合ひらがなに変換
      .replace(/[ァ-ヶ]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0x60))
      .toLowerCase()
      .trim()
  );
}

// タグ名、または読み仮名（漢字タグ用。未設定なら空）のどちらかにキーワードが含まれるか
export function matchesTag(keyword, name, reading = "") {
  return normalizeTag(name).includes(keyword) || normalizeTag(reading ?? "").includes(keyword);
}
