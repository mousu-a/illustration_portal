import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tagsInput"];

  convertToParams(e) {
    if (!this.hasTagsInputTarget) return;

    const form = e.target;
    const rawTagsInput = this.tagsInputTarget;
    const tagNames = rawTagsInput.value.trim().split(/\s+/).filter(Boolean);
    appendTagList(form, tagNames);

    rawTagsInput.disabled = true;
  }
}

function appendTagList(form, tagNames) {
  if (tagNames.length === 0) {
    appendHiddenTagInput(form, "");
    return;
  }
  tagNames.forEach((tagName) => appendHiddenTagInput(form, tagName));
}

function appendHiddenTagInput(form, tagName) {
  const hidden = document.createElement("input");
  hidden.type = "hidden";
  hidden.name = "reference_archive[tag_list][]";
  hidden.value = tagName;
  form.appendChild(hidden);
}
