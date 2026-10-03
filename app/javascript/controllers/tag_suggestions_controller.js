import { Controller } from "@hotwired/stimulus";
import { normalizeTag } from "lib/normalize_tag";

const MAX_SUGGESTIONS = 10;

export default class extends Controller {
  static targets = ["tagSuggestions", "input", "tag"];

  show() {
    if (!this.hasTagTarget) return;

    this.tagSuggestionsTarget.hidden = false;
    this.suggest();
  }

  suggest() {
    this.tagTargets.forEach((tag) => (tag.hidden = true));
    this.suggestionTags()
      .slice(0, MAX_SUGGESTIONS)
      .forEach((tag) => (tag.hidden = false));
  }

  suggestionTags() {
    const inputWords = this.inputTarget.value.split(/\s+/);
    const targetWord = inputWords.at(-1);
    const keyword = normalizeTag(targetWord);
    const alreadyEnteredTags = new Set(inputWords.slice(0, -1).map(normalizeTag));

    const matchedTags = this.tagTargets.filter((tag) => {
      const tagName = normalizeTag(tag.dataset.tagName);
      const isDuplicate = alreadyEnteredTags.has(tagName);
      return tagName.includes(keyword) && !isDuplicate;
    });

    return matchedTags;
  }

  completeInput(e) {
    const inputWords = this.inputTarget.value.split(/\s+/);
    const selectedWord = e.currentTarget.dataset.tagName;
    const targetIndex = inputWords.length - 1
    inputWords[targetIndex] = selectedWord

    const completedInput = inputWords.join(" ");
    this.inputTarget.value = completedInput + " ";
    this.inputTarget.focus();
    // 次のタグを入力するときのノイズになってしまうため、タグの補完直後はサジェストを表示しない
    this.tagTargets.forEach((tag) => (tag.hidden = true));
  }
}
