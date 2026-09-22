import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["error"];

  clearStaleErrors() {
    this.errorTargets.forEach((error) => error.remove());
  }
}
