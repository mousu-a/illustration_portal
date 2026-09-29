import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  async paste() {
    try {
      this.inputTarget.value = await navigator.clipboard.readText();
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }));
    } catch {
      this.inputTarget.focus();
    }
  }
}
