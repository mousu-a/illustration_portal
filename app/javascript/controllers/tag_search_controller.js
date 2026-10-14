import { Controller } from "@hotwired/stimulus";
import { normalizeTag } from "lib/normalize_tag";

export default class extends Controller {
  static targets = ["input", "tag", "matchLabel", "emptyLabel"];

  search() {
    if (!this.hasTagTarget) return;

    this.dispatch("search", { detail: { active: this.inputTarget.value.trim() !== "" } });

    const matchedTags = this.matchedTags();
    this.tagTargets.forEach((tag) => (tag.hidden = true));
    matchedTags.forEach((tag) => (tag.hidden = false));

    this.toggleResultLabels(matchedTags.length);
  }

  toggleResultLabels(resultCount) {
    const isMatched = resultCount > 0;
    this.emptyLabelTarget.hidden = isMatched;
    this.matchLabelTarget.hidden = !isMatched;
  }

  matchedTags() {
    const keyword = normalizeTag(this.inputTarget.value);

    const matchedTags = this.tagTargets.filter((tag) => {
      const tagName = normalizeTag(tag.dataset.tagSearchName);
      return tagName.includes(keyword);
    });

    return matchedTags;
  }
}
