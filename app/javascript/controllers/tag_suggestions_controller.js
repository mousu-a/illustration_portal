import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];

  show() {
    this.contentTargets.forEach((content) => (content.hidden = false));
  }
}
