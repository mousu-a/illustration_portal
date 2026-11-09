import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.returnFocusTo = document.activeElement;
    this.element.showModal();
  }

  close() {
    this.element.close();
  }

  // Escキーで閉じたときも close イベントが来るので、後片付けはここにまとめる
  remove() {
    this.element.remove();
    if (this.returnFocusTo?.isConnected) this.returnFocusTo.focus();
  }

  // dialog の padding を0にしているので、暗幕をクリックしたときだけ target が dialog 自身になる
  closeOnBackdrop(event) {
    if (event.target === this.element) this.close();
  }
}
