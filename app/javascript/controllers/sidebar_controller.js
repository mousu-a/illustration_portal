import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  open() {
    this.element.classList.add("is-sidebar-open");
  }

  close() {
    this.element.classList.remove("is-sidebar-open");
  }
}
