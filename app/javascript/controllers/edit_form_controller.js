import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["show", "editForm"];

  connect() {
    if (this.element.querySelector(".form-errors li")) {
      this.showTarget.classList.add("hidden");
      this.editFormTarget.classList.remove("hidden");
    }
  }

  toggle() {
    this.showTarget.classList.toggle("hidden");
    this.editFormTarget.classList.toggle("hidden");
  }
}
