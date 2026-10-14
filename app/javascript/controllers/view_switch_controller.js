import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["kanaSections", "resultsSection"];

  searching(e) {
    const active = e.detail.active;
    this.kanaSectionsTarget.hidden = active;
    this.resultsSectionTarget.hidden = !active;
  }
}
