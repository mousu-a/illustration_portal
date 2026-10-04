import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["message"];

  show() {
    this.messageTarget.hidden = false;
  }
}
