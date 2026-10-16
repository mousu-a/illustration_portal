import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];
  static values = { addMode: Boolean };

  get addMode() {
    return this.addModeValue;
  }

  toggle() {
    this.addModeValue = !this.addModeValue;
  }

  reset() {
    this.addModeValue = false;
  }

  toggleTargetConnected() {
    this.syncToggle();
  }

  addModeValueChanged() {
    this.syncToggle();
  }

  syncToggle() {
    const isAddMode = this.addModeValue;

    this.toggleTargets.forEach((button) => {
      button.classList.toggle("is-active", isAddMode);
      button.setAttribute("aria-pressed", String(isAddMode));
    });
  }
}
