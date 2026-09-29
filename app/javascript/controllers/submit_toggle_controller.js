import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["url", "submit"];

  connect() {
    this.toggle();
  }

  toggle() {
    this.submitTarget.disabled = this.urlTarget.value.trim() === "";
  }
}
