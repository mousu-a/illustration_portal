import { Controller } from "@hotwired/stimulus";
import { normalizeTag } from "lib/normalize_tag";

export default class extends Controller {
  static targets = ["input", "tag"];

  search() {
    this.tagTargets.forEach((tag) => (tag.hidden = true));
    this.matchedTags().forEach((tag) => (tag.hidden = false));
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
